# docker-python34-opencv


A Docker image running Debian with Python 3.4, the latest FFMPEG (built from source), and OpenCV 3 (built from source)



### To Build

~~~~
docker build -t <imageName> .
~~~~

### To pull and run from hub.docker.com

Docker Hub: https://registry.hub.docker.com/u/dkarchmervue/python34-opencv/

Source and example: https://github.com/ampervue/docker-python34-opencv

~~~~
docker pull dkarchmervue/python34-opencv
docker run -ti dkarchmervue/python34-opencv bash
~~~~

### Example

To demostrate how to use this image, see example/ where another Dockerfile is defined
to demonstrate how to build OpenCV C++ code, and then access it via a VNC Client:

git clone https://dkarchmer-vue@bitbucket.org/ampervue/python34-opencv.git
cd example
docker build -t opencvtest .
docker run -it --rm -p 5901:5901 -e USER=root opencvtest \
    bash -c "vncserver :1 -geometry 1280x800 -depth 24 && tail -F /root/.vnc/*.log"

Connect to vnc://<host>:5901 via VNC client.
On a terminal, call program with: `opencvtest sample.jpg` and open generated Gray_Image.jpg