# GetFPS

Get FPS/Frame rate by Android adb shell command.

# Install
Push scripts into Android device.
```
adb push utils.sh /data/local/tmp
adb push get_fps.sh /data/local/tmp
```

# Usage
- Print FPS of current top resumed app
```
$ source get_fps.sh
FPS: 59
```

- Print average render elapsed time of current top resumed app
```
$ source get_fps.sh -t
Average elapsed 20.54 ms
```

- Select target package instead of top resumed app
```
$ source get_fps.sh -p com.android.settings
```

- Loop
```
watch -tn1 "eval source get_fps.sh"
```

- Loop by while
```
while true
do
    source get_fps.sh
    sleep 1
done
```

# License
MIT License

Copyright (c) 2022 Niko Zhong

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

