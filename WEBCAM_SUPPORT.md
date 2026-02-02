# Webcam and Media Device Support

The kiosk configuration includes full support for webcams and microphones in Chrome.

## What's Configured

### 1. User Permissions
The kiosk user is added to the following groups:
- `video` - Access to video devices (webcams)
- `audio` - Access to audio devices (microphones)
- `camera` - Additional camera permissions

### 2. Chrome Flags
Chrome is launched with these media-related flags:
- `--use-fake-ui-for-media-stream` - Automatically grant media permissions
- `--auto-accept-camera-and-microphone-capture` - Skip permission prompts

### 3. udev Rules
Automatic rules ensure video devices are accessible:
```
SUBSYSTEM=="video4linux", GROUP="video", MODE="0660"
```

## Testing Webcam Access

### Check if Webcam is Detected

```bash
# List video devices
ls -l /dev/video*

# Should show something like:
# crw-rw---- 1 root video 81, 0 Feb  1 10:00 /dev/video0

# Check detailed info
v4l2-ctl --list-devices

# Test with a simple capture (requires ffmpeg)
ffmpeg -f v4l2 -i /dev/video0 -frames 1 test.jpg
```

### Test in Chrome

1. SSH into the kiosk or use a TTY (Ctrl+Alt+F2)
2. Run these commands:

```bash
su - kiosk
DISPLAY=:0 google-chrome-stable https://webcamtests.com
```

This will open a webcam test site where you can verify camera functionality.

## Common Webcam Issues

### Issue: "Camera not found" or "Permission denied"

**Check user groups:**
```bash
groups kiosk
# Should include: video audio camera
```

**Check device permissions:**
```bash
ls -l /dev/video0
# Should show: crw-rw---- 1 root video
```

**Fix permissions:**
```bash
sudo usermod -aG video,audio,camera kiosk
sudo reboot
```

### Issue: Chrome asks for permission despite auto-accept flags

**Solution 1: Add policy file**

Create `/etc/chromium/policies/managed/media.json`:
```json
{
  "AudioCaptureAllowed": true,
  "VideoCaptureAllowed": true,
  "AudioCaptureAllowedUrls": ["https://login.experienceco.com"],
  "VideoCaptureAllowedUrls": ["https://login.experienceco.com"]
}
```

Add to `kiosk-common.nix`:
```nix
environment.etc."chromium/policies/managed/media.json".text = ''
  {
    "AudioCaptureAllowed": true,
    "VideoCaptureAllowed": true,
    "AudioCaptureAllowedUrls": ["https://login.experienceco.com"],
    "VideoCaptureAllowedUrls": ["https://login.experienceco.com"]
  }
'';
```

**Solution 2: Use command-line flags (already included)**

The configuration already includes:
- `--use-fake-ui-for-media-stream`
- `--auto-accept-camera-and-microphone-capture`

### Issue: Webcam works but quality is poor

**Adjust resolution and framerate:**

```bash
# Check supported formats
v4l2-ctl --list-formats-ext

# Set specific format (example)
v4l2-ctl --set-fmt-video=width=1920,height=1080,pixelformat=MJPG
```

To make permanent, add to `kiosk-common.nix`:
```nix
boot.kernelModules = [ "uvcvideo" ];
boot.extraModprobeConfig = ''
  options uvcvideo nodrop=1 timeout=5000 quirks=0x80
'';
```

### Issue: Multiple cameras detected, wrong one selected

**List all cameras:**
```bash
v4l2-ctl --list-devices
```

**Force specific camera:**

Add a udev rule in `kiosk-common.nix`:
```nix
services.udev.extraRules = ''
  # Set primary camera
  SUBSYSTEM=="video4linux", KERNEL=="video0", ATTR{index}=="0", SYMLINK+="video-primary"
'';
```

## Supported Hardware

Most USB webcams work out of the box, including:
- Logitech C920, C922, C930e
- Microsoft LifeCam
- Generic UVC (USB Video Class) webcams
- Built-in laptop cameras
- Raspberry Pi Camera Module (requires additional config)

## Advanced Configuration

### Enable Multiple Cameras

```nix
# In kiosk-common.nix
services.udev.extraRules = ''
  SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", GROUP="video", MODE="0660"
  
  # Label cameras by position
  SUBSYSTEM=="video4linux", ATTRS{product}=="Logitech*", SYMLINK+="video-logitech"
  SUBSYSTEM=="video4linux", ATTRS{product}=="Microsoft*", SYMLINK+="video-microsoft"
'';
```

### Audio Device Configuration

If you have issues with microphone selection:

```nix
# List audio devices
hardware.pulseaudio.extraConfig = ''
  load-module module-alsa-source device=hw:0,0
  set-default-source alsa_input.usb-*
'';
```

### Hardware Acceleration for Video

Enable VA-API for better video performance:

```nix
hardware.opengl = {
  enable = true;
  driSupport = true;
  extraPackages = with pkgs; [
    intel-media-driver  # For Intel GPUs
    vaapiVdpau
    libvdpau-va-gl
  ];
};

# Add to Chrome flags in openbox autostart:
--enable-features=VaapiVideoDecoder \
--use-gl=desktop \
```

## Testing Script

Save this as `test-webcam.sh`:

```bash
#!/usr/bin/env bash

echo "=== Webcam Diagnostics ==="
echo ""

echo "1. Checking video devices..."
ls -l /dev/video* 2>/dev/null || echo "No video devices found!"
echo ""

echo "2. Checking user groups..."
groups $(whoami)
echo ""

echo "3. Checking v4l2 capabilities..."
if command -v v4l2-ctl &> /dev/null; then
    v4l2-ctl --list-devices
else
    echo "v4l2-utils not installed"
fi
echo ""

echo "4. Checking Chrome process..."
ps aux | grep chrome | grep -v grep || echo "Chrome not running"
echo ""

echo "5. Testing camera access..."
if [ -c /dev/video0 ]; then
    if [ -r /dev/video0 ] && [ -w /dev/video0 ]; then
        echo "✓ Camera is accessible"
    else
        echo "✗ Camera found but not accessible (permission issue)"
    fi
else
    echo "✗ No camera device found"
fi
```

Run with:
```bash
chmod +x test-webcam.sh
./test-webcam.sh
```

## Security Considerations

### Auto-accepting media permissions is convenient but:

1. **Any website** loaded in the kiosk could access camera/microphone
2. Consider restricting to your specific domain

### To restrict to your domain only:

Remove these flags:
- `--use-fake-ui-for-media-stream`
- `--auto-accept-camera-and-microphone-capture`

And add a policy file as shown in Solution 1 above, which limits access to specific URLs.

### For high-security environments:

Consider using a USB webcam with a physical privacy shutter, or add a systemd service to disable the camera when not in use:

```nix
systemd.services.camera-privacy = {
  description = "Disable camera by default";
  wantedBy = [ "multi-user.target" ];
  script = ''
    echo 0 > /sys/bus/usb/devices/*/authorized
  '';
};
```

## Troubleshooting Checklist

- [ ] Webcam is plugged in and detected (`ls /dev/video*`)
- [ ] User is in video, audio, camera groups (`groups kiosk`)
- [ ] Device permissions are correct (`ls -l /dev/video0`)
- [ ] Chrome has correct flags (check openbox autostart)
- [ ] No other application is using the camera (`lsof /dev/video0`)
- [ ] Kernel module is loaded (`lsmod | grep uvcvideo`)
- [ ] Chrome site permissions are not blocking (check chrome://settings/content)

## Still Having Issues?

1. Check Chrome's WebRTC internals: `chrome://webrtc-internals`
2. Check media device enumeration: `chrome://media-internals`
3. View Chrome logs: `chrome://gpu` for GPU/video acceleration issues
4. Enable verbose logging:
   ```nix
   --enable-logging=stderr --v=1
   ```
