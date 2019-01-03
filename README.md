<h1 align="center">
ReplayRecorder
<br>
</h1>

## Usage

```
let configuration: Configuration = Configuration()
let recorder = ReplayRecorder(configuration: configuration)
recorder.cropRect = CGRect(x: 0.2, y: 0.2, width: 0.5, height: 0.5)
recorder.filter = CIFilter(name: "CISepiaTone")

...
recorder.startRecording()
...

recorder.stopRecording { (url, error) in
  // saved url
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ReplayRecorder is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ReplayRecorder'
```

## Author

noppefoxwolf, noppelabs@gmail.com

## License

ReplayRecorder is available under the MIT license. See the LICENSE file for more info.
