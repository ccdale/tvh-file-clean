# Clean up Tvheadend Created .ts files #

This script is a pre-cursor to attempting to use mythcommflag to create a cut list for projectx.

It uses projectx to demux the transport stream and mplex to remux it into an mpeg2 format file.  This picks up any
dropped frames and ensures that the sound and video are in sync.

You'll need [project-x](https://sourceforge.net/projects/project-x/) and mplex
from [mjpegtools](http://mjpeg.sourceforge.net/)

In ubuntu they can be found in the package repositories:

```
sudo apt install project-x mjpegtools
```

Once the recording has been cleaned up it is copied back over the original to ensure that it can be found ok by
tvheadend/kodi.
