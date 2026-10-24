# smagic

I created this Linux script to standardize how I process the WAV file created by Suno for various uses. Originally most of this was done using audacity, but then I learned that audacity actually used the same library as the CLI tool sox.

This script takes a single input (for example 'track_name') and expects to find a SUNO created track_name.wav file (which is sampled at 48 kHz) and a track_name.jpb file (which is a 1600x1600, or at least a square) album art graphic. It then creates the following files:

- **artist - track_name_RAW.wav** is the input WAV file converted to a sample rate of 44.1kHz.
- **artist - track_name_MSTR.wav** is normalized to -1 dB with full dynamic range.
- **artist - track_name_COMP.wav** has the compressed audio for streaming services.
- **artist - track_name.mp3** is the MP3 file with tags and album art.
- **artist - track_name.mp4** has the square album art for social media.
- **artist - track_name_YT.mp4** has album art streched for YouTube.

My two main goals were to make the process of dealing with all of this easier and also to ensure consistency in the music I release.

The tool is likely to evolve as I encounter new issues or use cases. For example, I had one song that was suddenly chopped off at the end instead of having a proper fade-out. This script now pulls up volume information for the track as whole and for the last half second to give you an idea is there might be a similar problem with another file.

This might be something you largely use as is or something that you take and tailor to how you do things. For example, I like to upload an MP4 with the album art as the 'video' component of the file to some platforms even though some will accept an MP3 and extract the album art from it. This is because I have had mixed results using the MP3 while the MP4 approach seems to work consistently.

## Shameless Plug

You can listen to music by The Daft Spaniels on most streaming platforms as well as on Facebook and YouTube. The music covers a variety of styles and genres. It is about learning and having fun while making music that allows expression.

## The Fine Print
Suno is a registered trademark of Suno, Inc., a generative artificial intelligence music company based in Cambridge, Massachusetts.

This script is intended for personal use only. The user accepts responsibility for ensuring their use of this script does not violate any terms, conditions, or policies of platforms as Suno.

To the extent applicable, any original work herein is Copyright 2026 by James McClanahan.

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. 
- **Open Source:** Anyone can use, modify, and distribute this software for free.
- **Share Alike:** If you modify this code or use it in your own project, your derivative work **must** also be open-sourced under the GPLv3.
- **No Commercial Lock-in:** You cannot use this code in proprietary (closed-source) software.
- **License Inclusion:** You must include the original copyright notice and a copy of the GPLv3 license with any distribution.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
