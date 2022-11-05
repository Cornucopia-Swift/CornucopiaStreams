//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaStreams
import Foundation
import LineNoise

@main
class Streamer: NSObject {

    static let inputBufferSize = 4096
    lazy var inputBuffer: [UInt8] = .init(repeating: 0, count: Self.inputBufferSize)
    lazy var outputBuffer: [UInt8] = []
    lazy var stdout = FileHandle.standardOutput
    let runloop = RunLoop.current

    func usage() {
        print("Usage: ./streamer <url>")
        Foundation.exit(-1)
    }

    static func main() {

        let stream = Streamer()

        guard CommandLine.arguments.count == 2 else { return stream.usage() }
        guard let url = URL(string: CommandLine.arguments[1]) else { return stream.usage() }
        print("Connecting to \(url)...")
        Task {
            do {
                try await stream.connect(url)
            } catch {
                print("Error: \(error)")
                Foundation.exit(-1)
            }
        }

        while true {
            print("running")
            RunLoop.current.run(until: .distantFuture)
        }
    }

    func connect(_ url: URL) async throws {

        let streams = try await Cornucopia.Streams.connect(url: url)
        print("Connected to \(url)")
        streams.0.delegate = self
        streams.1.delegate = self
        streams.0.schedule(in: self.runloop, forMode: .default)
        streams.1.schedule(in: self.runloop, forMode: .default)
        streams.0.open()
        streams.1.open()

        defer {
            streams.0.close()
            streams.1.close()
            streams.0.remove(from: self.runloop, forMode: .default)
            streams.1.remove(from: self.runloop, forMode: .default)
        }

        let ln = LineNoise()

        repeat {
            var input = ""
            do {
                input = try ln.getLine(prompt: "")
            } catch LinenoiseError.CTRL_C, LinenoiseError.EOF {
                print("^D")
                break
            } catch {
                print("Unhandled error: \(error)")
                break
            }

            if !input.isEmpty {
                guard !input.hasPrefix("quit") else {
                    print("")
                    break
                }
                input += "\r"
                self.outputBuffer = Array(input.utf8)
                streams.1.write(&self.outputBuffer, maxLength: input.count)
            }
        } while true

        Foundation.exit(0)
    }

    func read(from stream: InputStream) {

        let length = stream.read(&self.inputBuffer, maxLength: 4096)
        try! self.stdout.write(contentsOf: self.inputBuffer[0...length])
    }
}

extension Streamer: StreamDelegate {

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {

        print("\(aStream): \(eventCode)")

        switch (aStream, eventCode) {

            case (is InputStream, .hasBytesAvailable):
                self.read(from: aStream as! InputStream)

            default:
                break
        }

    }

}
