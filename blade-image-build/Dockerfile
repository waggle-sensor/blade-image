# ANL:waggle-license
#  This file is part of the Waggle Platform.  Please see the file
#  LICENSE.waggle.txt for the legal details of the copyright and software
#  license.  For more details on the Waggle project, visit:
#           http://www.wa8.gl
# ANL:waggle-license

FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
  mkisofs \
  wget \
  p7zip-full \
  p7zip-rar

COPY ROOTFS/ /

WORKDIR /opt/sage/blade/image/

RUN chmod +x build_image.sh

CMD ["./build_image.sh"]

