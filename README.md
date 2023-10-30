# ReachabilitySDK
Extreme simple API for determining a stable Internet connection, https://pingspeed.click

## Install via SPM
https://github.com/pingspeedsdk/ReachabilitySDK

### Get network condition by simple request
```swift
let networkState = await PSReachability.shared.updateReachability()
```
observe state anyplace, hook changes by observe notification service (fire after updateReachability call)

```swift
NotificationCenter.default.addObserver(self,
                                      selector: #selector(selector),
                                      name: Notification.Name.reachabilityChanged,
                                      object: nil)
```

We opened to any codebase conribution, star repo if enjoy.
