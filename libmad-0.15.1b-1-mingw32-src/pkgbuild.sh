#! /bin/bash

name=libmad
badname=libmad
ver=0.15.1b
ver1=0
ver2=0.15
dllver=0
rev=1
subsys=mingw32
srcname=${name}-${ver}
prefix=/mingw
reldoc=share/doc/${badname}/${ver}
SOURCE_ARCHIVE_FORMAT=.tar.gz
SOURCE_ARCHIVE=${name}-${ver}${SOURCE_ARCHIVE_FORMAT}
preconf_patches=
docfiles="README \
ChangeLog \
NEWS"
licfiles="AUTHORS \
COPYING"

url=http://sourceforge.net/projects/mad/files/libmad/0.15.1b/${SOURCE_ARCHIVE}/download
md5='1be543bc30c56fb6bea1d7bf6a64e66c'

if test ! "$MSYSTEM" == "MSYS" -a "$subsys" == "msys"
then
  echo "You must be in an MSYS shell to build a msys package"
  exit 4
fi

if test ! "$MSYSTEM" == "MINGW32" -a "$subsys" == "mingw32"
then
  echo "You must be in an MINGW shell to build a mingw32 package"
  exit 5
fi

pkgbuilddir=`pwd` || fail $LINENO
echo Acting from the directory ${pkgbuilddir}

patchfiles=`for i in ${pkgbuilddir}/patches/*.${subsys}.patch ${pkgbuilddir}/patches/*.all.patch; do if test $(expr index "$i" "*") -ge 1; then : ;else echo $i; fi; done | sort`

instdir=${pkgbuilddir}/inst
blddir=${pkgbuilddir}/bld
logdir=${pkgbuilddir}/logs
srcdir=${pkgbuilddir}/${name}-${ver}

echo The source directory is ${srcdir}

srcdirname=$(basename ${srcdir})

capname=Unknown
if test "x${subsys}" == "xmingw32"
then
capname=MinGW
elif test "x${subsys}" == "xmsys"
then
capname=MSYS
fi

_sysver=$(uname -r)
export SYSVER=${_sysver%%\(*}

pkgtmp=${badname}-${ver}-${rev}-${subsys}
BINPKG=${pkgtmp}-bin.tar.lzma
DEVPKG=${pkgtmp}-dev.tar.lzma
DLLPKG=${badname}-${ver}-${rev}-${subsys}-dll-${dllver}.tar.lzma
DOCPKG=${pkgtmp}-doc.tar.lzma
LICPKG=${pkgtmp}-lic.tar.lzma
COMPKG=${badname}-${ver}-${rev}-msys-${SYSVER}-completion.tar.lzma
LANGPKG=${pkgtmp}-lang.tar.lzma
SRCPKG=${pkgtmp}-src.tar.lzma
BIN_CONTENTS=""
DEV_CONTENTS="--exclude=*.dll --exclude=*.la lib include bin"
DLL_CONTENTS="bin/*.dll"
LIC_CONTENTS="$(for i in $licfiles; do echo $reldoc/$i; done)"
DOC_CONTENTS="share/doc/${badname}/${ver}"
LIC_CONTENTS="$LIC_CONTENTS $(for i in $docfiles; do echo --exclude=$i; done)"
DOC_CONTENTS="$DOC_CONTENTS $(for i in $licfiles; do echo --exclude=$i; done) share/doc/${capname}"
COM_CONTENTS="etc/bash_completion.d"
LANG_CONTENTS="share/locale"
SRC_CONTENTS="pkgbuild.sh \
${subsys}-${badname}.RELEASE_NOTES \
patches \
${SOURCE_ARCHIVE}"

do_download=1
do_unpack=1
do_patch=1
do_preconfigure=0
do_reconfigure=1
do_configure=1
do_make=1
do_check=0
do_install=1
do_fixinstall=1
do_pack=1

if test ! "x$reposrc" = "x"
then
  srcdir="$reposrc"
  do_download=0
  do_unpack=0
  do_reconfigure=1
fi

zeroall() {
      do_download=0
      do_unpack=0
      do_patch=0
      do_preconfigure=0
      do_reconfigure=0
      do_configure=0
      do_make=0
      do_check=0
      do_install=0
      do_fixinstall=0
      do_pack=0
}

while [ $# -gt 0 ]
do
  case $1 in
    --download) do_download=1 ; shift 1 ;;
    --unpack) do_unpack=1 ; shift 1 ;;
    --patch) do_patch=1 ; shift 1 ;;
    --preconfigure) do_preconfigure=1 ; shift 1 ;;
    --reconfigure) do_reconfigure=1 ; shift 1 ;;
    --configure) do_configure=1 ; shift 1 ;;
    --make) do_make=1 ; shift 1 ;;
    --check) do_check=1 ; shift 1 ;;
    --install) do_install=1 ; shift 1 ;;
    --fixinstall) do_fixinstall=1 ; shift 1 ;;
    --pack) do_pack=1 ; shift 1 ;;
    --download-only) zeroall; do_download=1 ; shift 1 ;;
    --unpack-only) zeroall; do_unpack=1 ; shift 1 ;;
    --patch-only) zeroall; do_patch=1 ; shift 1 ;;
    --preconfigure-only) zeroall; do_preconfigure=1 ; shift 1 ;;
    --reconfigure-only) zeroall; do_reconfigure=1 ; shift 1 ;;
    --configure-only) zeroall; do_configure=1 ; shift 1 ;;
    --make-only) zeroall; do_make=1 ; shift 1 ;;
    --check-only) zeroall; do_check=1 ; shift 1 ;;
    --install-only) zeroall; do_install=1 ; shift 1 ;;
    --fixinstall-only) zeroall; do_fixinstall=1 ; shift 1 ;;
    --pack-only) zeroall; do_pack=1 ; shift 1 ;;
    *) shift 1 ;;
  esac
done


fail() {
  echo "failure at line $1"
  exit 1
}

if test ! -d ${logdir}
then
  mkdir -p ${logdir} || fail $LINENO
fi

if test "x$do_download" == "x1"
then
  rm -f ${logdir}/download.log
  test -f ${pkgbuilddir}/${SOURCE_ARCHIVE} || {
    echo "Downloading ${SOURCE_ARCHIVE} ..." 2>&1 | tee ${logdir}/download.log
    wget -O ${pkgbuilddir}/${SOURCE_ARCHIVE} $url 2>&1 | tee -a ${logdir}/download.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  }

  echo "Verifying md5 sum ..." | tee -a ${logdir}/download.log
  echo "$md5 *${pkgbuilddir}/${SOURCE_ARCHIVE}" > ${SOURCE_ARCHIVE}.md5
  md5sum -c --status ${SOURCE_ARCHIVE}.md5 2>&1 | tee -a ${logdir}/download.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  rm ${SOURCE_ARCHIVE}.md5 2>&1 | tee -a ${logdir}/download.log
  echo "Done downloading"
fi

if test "x$do_unpack" == "x1"
then
  rm -f ${logdir}/unpack.log
  if test ! "x${srcdir}" == "x/" -a ! "x${srcdir}" == "x" -a ! "x${srcdir}" == "x${pkgbuilddir}"
  then
    echo "Deleting ${srcdir} contents" | tee ${logdir}/unpack.log
    rm -rf ${srcdir}/* 2>&1 | tee -a ${logdir}/unpack.log
  else
    echo "I think it is unsafe to delete ${srcdir}" | tee ${logdir}/unpack.log
    exit 2
  fi

  echo Cleaning up inst and build directories | tee -a ${logdir}/unpack.log
  rm -rf ${blddir} ${instdir} 2>&1 | tee -a ${logdir}/unpack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  cd ${pkgbuilddir} && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  echo "Unpacking $SOURCE_ARCHIVE in `pwd`" | tee -a ${logdir}/unpack.log
  case "$SOURCE_ARCHIVE" in
  *.tar.bz2 ) tar xjf $SOURCE_ARCHIVE 2>&1 | tee -a ${logdir}/unpack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi;;
  *.tar.gz  ) tar xzf $SOURCE_ARCHIVE 2>&1 | tee -a ${logdir}/unpack.log  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi;;
  *.zip     ) unzip -q $SOURCE_ARCHIVE  2>&1 | tee -a ${logdir}/unpack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi;;
  *.tar.lzma) tar --lzma -xf $SOURCE_ARCHIVE 2>&1 | tee -a ${logdir}/unpack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi;;
  *.tar.xz) tar xJf $SOURCE_ARCHIVE 2>&1 | tee -a ${logdir}/unpack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi;;
  esac
  if test $(ls ${srcdir} -l | wc -l) -ge 2
  then
    echo "Unpacked into ${srcdir} successfully!" | tee -a ${logdir}/unpack.log
  else
    echo "${srcdir} is empty - did not unpack into it?" | tee -a ${logdir}/unpack.log
    exit 3
  fi
  echo "Done unpacking"
fi

patch_list=
if test "x$do_patch" == "x1"
then
  rm -f ${logdir}/patch.log
  echo cd ${srcdir}
  cd ${srcdir} && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  if test ! "x${patchfiles}" == "x"
  then
    echo "Patching in `pwd` from patchfiles ${patchfiles}" | tee -a ${logdir}/patch.log
  fi
  for patchfile in ${patchfiles}
  do
    if test ! "x${patchfiles}" == "x"
    then
      echo "Applying ${patchfile}" | tee -a ${logdir}/patch.log
      patch -p1 -i ${patchfile} 2>&1 | tee -a ${logdir}/patch.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
    fi
    patch_list="$patch_list $patchfile"
  done
  echo "Done patching"
fi
rm ${srcdir}/aclocal.m4
rm ${srcdir}/Makefile.in

if test "x$do_reconfigure" == "x1"
then
  cd ${srcdir}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  echo Reconfiguring in `pwd` | tee -a ${logdir}/reconfigure.log
  touch NEWS AUTHORS ChangeLog
  autoreconf -fi 2>&1 | tee -a ${logdir}/reconfigure.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
elif test "x$do_preconfigure" == "x1"
then
  cd ${srcdir}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  echo Patching in `pwd` from ${preconf_patches} | tee -a ${logdir}/reconfigure.log
  for patchfile in ${pkgbuilddir}/preconf-patches/*${subsys}.patch
  do
    patch -p0 -i ${patchfile} 2>&1 | tee -a ${logdir}/reconfigure.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  done
fi

mkdir -p ${blddir} || fail $LINENO

if test "x$do_configure" == "x1"
then
  rm -f ${logdir}/configure.log
  cd ${blddir} && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  #lndir ${srcdir} . 2>&1 | tee -a ${logdir}/configure.log
  echo Configuring in `pwd` | tee -a ${logdir}/configure.log

  CFLAGS="$CFLAGS -march=i686 -O2" ${srcdir}/configure --prefix=${prefix} --enable-shared --disable-static 2>&1 | tee -a ${logdir}/configure.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
fi

if test "x$do_make" == "x1"
then
  rm -f ${logdir}/make.log
  cd ${blddir}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  echo Making
  make $MAKEFLAGS 2>&1 | tee -a ${logdir}/make.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
fi

if test "x$do_install" == "x1"
then
  rm -f ${logdir}/install.log
  cd ${blddir}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  echo Installing into ${instdir} from `pwd` | tee ${logdir}/install.log
  make install DESTDIR=${instdir} $MAKEFLAGS 2>&1 | tee -a ${logdir}/install.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
fi

if test "x$do_check" == "x1"
then
  rm -f ${logdir}/test.log
  cd ${blddir}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  echo "Testing" | tee -a ${logdir}/test.log
  make -k check 2>&1 | tee -a ${logdir}/test.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
fi


if test "x$do_fixinstall" == "x1"
then
  rm -f ${logdir}/fixinstall.log
  echo Fixing the installation | tee ${logdir}/fixinstall.log
  mkdir -p ${instdir}${prefix}/share/doc/${badname}/${ver} 2>&1 | tee -a ${logdir}/fixinstall.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  cd ${srcdir}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  for f in ${docfiles} ${licfiles}
  do
    if test -f ${instdir}${prefix}/${reldoc}/$(basename ${f})
    then
      cp -r ${f} ${instdir}${prefix}/${reldoc}/${f}
    else
      cp -r ${f} ${instdir}${prefix}/${reldoc}/$(basename ${f})
    fi
  done
  mkdir -p ${instdir}${prefix}/share/doc/${capname} 2>&1 | tee -a ${logdir}/fixinstall.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  cp ${pkgbuilddir}/${subsys}-${badname}.RELEASE_NOTES \
    ${instdir}${prefix}/share/doc/${capname}/${badname}-${ver}-${rev}-${subsys}.RELEASE_NOTES.txt 2>&1 | tee -a ${logdir}/fixinstall.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
fi

if test "x$do_pack" == "x1"
then
  rm -f ${logdir}/pack.log
  cd ${instdir}${prefix}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  echo Packing | tee -a ${logdir}/pack.log
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${DEVPKG} ${DEV_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${DOCPKG} ${DOC_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${LICPKG} ${LIC_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${DLLPKG} ${DLL_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  cd ${pkgbuilddir}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${SRCPKG} ${SRC_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
fi

echo "Done"
exit 0
