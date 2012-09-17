#! /bin/bash

name=flac
badname=flac
dllver=8
dllvercpp=6
rev=1
subsys=mingw32
d1_srcname="\${name}-\${ver}"
prefix=/mingw
d1_reldoc="share/doc/\${badname}/\${ver}"
SOURCE_ARCHIVE_FORMAT=.tar.xz
d1_SOURCE_ARCHIVE="\${name}-\${ver}\${SOURCE_ARCHIVE_FORMAT}"
SOURCE_ARCHIVE_PATTERN="${name}-*${SOURCE_ARCHIVE_FORMAT}"
preconf_patches=
docfiles="README"
licfiles="AUTHORS \
COPYING.FDL \
COPYING.GPL \
COPYING.LGPL \
COPYING.Xiph"

repo_url=git://git.xiph.org/flac.git
get_version="git"

d1_pkgtmp="\${badname}-\${ver}-\${rev}-\${subsys}"
d1_BINPKG="\${pkgtmp}-bin.tar.lzma"
d1_DEVPKG="\${pkgtmp}-dev.tar.lzma"
d1_DLLPKG="lib\${badname}-\${ver}-\${rev}-\${subsys}-dll-\${dllver}.tar.lzma"
d1_DLLCPPPKG="lib\${badname}++-\${ver}-\${rev}-\${subsys}-dll-\${dllvercpp}.tar.lzma"
d1_DOCPKG="\${pkgtmp}-doc.tar.lzma"
d1_LICPKG="\${pkgtmp}-lic.tar.lzma"
d1_COMPKG="\${badname}-\${ver}-\${rev}-msys-\${SYSVER}-completion.tar.lzma"
d1_LANGPKG="\${pkgtmp}-lang.tar.lzma"
d1_SRCPKG="\${pkgtmp}-src.tar.lzma"
d1_BIN_CONTENTS="--exclude=bin/*.dll bin"
d1_DEV_CONTENTS="share/aclocal --exclude=*.dll --exclude=*.la lib include"
d1_DLL_CONTENTS="--exclude=*++-*.dll bin/*.dll"
d1_DLLCPP_CONTENTS="bin/*++-*.dll"
d1_LIC_CONTENTS="\$(for i in \$licfiles; do echo \$reldoc/\$i; done)"
d1_DOC_CONTENTS="share/doc/\${badname}/\${ver}"
d2_LIC_CONTENTS="\$LIC_CONTENTS \$(for i in \$docfiles; do echo --exclude=\$i; done)"
d2_DOC_CONTENTS="\$DOC_CONTENTS \$(for i in \$licfiles; do echo --exclude=\$i; done) share/doc/\${capname} share/man"
d1_COM_CONTENTS="etc/bash_completion.d"
d1_LANG_CONTENTS="share/locale"
d1_SRC_CONTENTS="pkgbuild.sh \
\${subsys}-\${badname}.RELEASE_NOTES \
\${subsys}-\${badname}.RELEASE_NOTES.in \
patches \
\${SOURCE_ARCHIVE}"

changelog="First release of ${name} for mingw using new packaging standard. "

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
repodir=${pkgbuilddir}/repo
d1_srcdir="\${pkgbuilddir}/\${name}-\${ver}"
srcdir_pattern="${pkgbuilddir}/${name}-*"

d1_srcdirname="\$(basename \${srcdir})"

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

do_clone=1
do_copy=1
do_patch=1
do_preconfigure=0
do_reconfigure=1
do_configure=1
do_make=1
do_check=0
do_install=1
do_fixinstall=1
do_pack=1

if test ! "x$repodir" = "x"
then
  do_clone=1
  do_copy=1
  do_reconfigure=1
fi

zeroall() {
      do_clone=0
      do_download=0
      do_unpack=0
      do_copy=0
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
    --patch) do_patch=1 ; shift 1 ;;
    --preconfigure) do_preconfigure=1 ; shift 1 ;;
    --reconfigure) do_reconfigure=1 ; shift 1 ;;
    --configure) do_configure=1 ; shift 1 ;;
    --make) do_make=1 ; shift 1 ;;
    --check) do_check=1 ; shift 1 ;;
    --install) do_install=1 ; shift 1 ;;
    --fixinstall) do_fixinstall=1 ; shift 1 ;;
    --pack) do_pack=1 ; shift 1 ;;
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

if test "x$do_clone" == "x1"
then
  if test ! -d "${repodir}"; then
    mkdir -p ${repodir} # Don't fail if exists
    git clone ${repo_url} ${repodir} || fail $LINENO
    cd ${repodir}
    git submodule init
    git submodule update
  else
    pushd .
    cd ${repodir}
    git fetch || fail $LINENO
    git rebase || fail $LINENO
    popd
  fi
fi

if test "x$get_version" == "xgit"
then
  commit=$(cd ${repodir} && git log --no-color -1 | grep -e 'commit [0-9a-f]\{40\}' | sed -e 's/commit \([0-9a-f]\{40\}\)/\1/')
  echo commit = $commit

  if [ ! -n "$commit" ]; then
    exit 1
  fi

  #Check if this commit matches a tag
  tag=$(cd ${repodir} && git tag --contains $commit 2>/dev/null)
  echo tag = \'$tag\'

  if [ -n "$tag" ]; then
    #Matches a tag, use tag as version
    version=$tag
    eval $(echo -e "v=\"$tag\"\nv1=v\nv2=v\ndot1=v.find('.')\nif dot1 > 0:\n  v1=v1[:dot1]\n  minus=v1.rfind('-')\n  if minus > 0:\n    v1=v1[minus+1:]\n  dot2=v2[dot1+1:].find('.')\n  if dot2 > 0:\n    v2=v2[:dot1+1+dot2]\nprint ('ver={}\nver1={}\nver2={}'.format (v, v1, v2))" | python)
  else
    #No tag for this commit, use commit hash as version
    version=git-$commit
    ver=git-$commit
    ver1=git-$commit
    ver2=git-$commit
  fi
fi

reldoc=$(eval echo $d1_reldoc)
SOURCE_ARCHIVE=$(eval echo $d1_SOURCE_ARCHIVE)

pkgtmp=$(eval echo $d1_pkgtmp)
BINPKG=$(eval echo $d1_BINPKG)
DEVPKG=$(eval echo $d1_DEVPKG)
DLLPKG=$(eval echo $d1_DLLPKG)
DLLCPPPKG=$(eval echo $d1_DLLCPPPKG)
DOCPKG=$(eval echo $d1_DOCPKG)
LICPKG=$(eval echo $d1_LICPKG)
COMPKG=$(eval echo $d1_COMPKG)
LANGPKG=$(eval echo $d1_LANGPKG)
SRCPKG=$(eval echo $d1_SRCPKG)
BIN_CONTENTS=$(eval echo $d1_BIN_CONTENTS)
DEV_CONTENTS=$(eval echo $d1_DEV_CONTENTS)
DLL_CONTENTS=$(eval echo $d1_DLL_CONTENTS)
DLLCPP_CONTENTS=$(eval echo $d1_DLLCPP_CONTENTS)
LIC_CONTENTS=$(eval echo $d1_LIC_CONTENTS)
DOC_CONTENTS=$(eval echo $d1_DOC_CONTENTS)
LIC_CONTENTS=$(eval echo $d2_LIC_CONTENTS)
DOC_CONTENTS=$(eval echo $d2_DOC_CONTENTS)
COM_CONTENTS=$(eval echo $d1_COM_CONTENTS)
LANG_CONTENTS=$(eval echo $d1_LANG_CONTENTS)
SRC_CONTENTS=$(eval echo $d1_SRC_CONTENTS)
srcdir=$(eval echo $d1_srcdir)
srcdirname=$(eval echo $d1_srcdirname)

echo "Source directory is $srcdir"

if test "x$do_copy" == "x1"
then
  rm -f "${logdir}/copy.log"

  if test ! "x${srcdir}" == "x/" -a ! "x${srcdir}" == "x" -a ! "x${srcdir}" == "x${pkgbuilddir}"
  then
    echo "Deleting ${srcdir} contents" | tee ${logdir}/copy.log
    rm -rf "${srcdir}" 2>&1 | tee -a ${logdir}/copy.log
    echo "Deleting directories matching ${srcdir_pattern}" | tee ${logdir}/copy.log
    for d in ${srcdir_pattern}
    do 
      if test -d $d
      then
        echo "Deleting $d" | tee ${logdir}/copy.log
        rm -rf $d
      fi
    done
    echo "Deleting files matching ${SOURCE_ARCHIVE_PATTERN}" | tee ${logdir}/copy.log
    for f in ${SOURCE_ARCHIVE_PATTERN}
    do 
      if test -f $f
      then
        echo "Deleting $f" | tee ${logdir}/copy.log
        rm -f $f
      fi
    done
  else
    echo "I think it is unsafe to delete ${srcdir}" | tee "${logdir}/copy.log"
    exit 2
  fi
  
  echo Cleaning up src, inst and build directories | tee -a "${logdir}/copy.log"
  rm -rf "${blddir}" "${instdir}" "${srcdir}" 2>&1 | tee -a "${logdir}/copy.log" && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  cd "${pkgbuilddir}" && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  echo "Copying from $repodir to $srcdir" | tee -a "${logdir}/copy.log"
  cp -rf "$repodir" "$srcdir" | tee -a "${logdir}/copy.log"
  tar cJv --hard-dereference -f "${pkgbuilddir}/${SOURCE_ARCHIVE}" $(basename ${repodir}) 2>&1 | tee -a "${logdir}/copy.log" && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  echo "Done copying"
fi

patch_list=
if test "x$do_patch" == "x1"
then
  rm -f "${logdir}/patch.log"
  echo cd "${srcdir}"
  cd "${srcdir}" && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  if test ! "x${patchfiles}" == "x"
  then
    echo "Patching in `pwd` from patchfiles ${patchfiles}" | tee -a ${logdir}/patch.log
  fi
  for patchfile in ${patchfiles}
  do
    if test ! "x${patchfiles}" == "x"
    then
      echo "Applying ${patchfile}" | tee -a ${logdir}/patch.log
      patch -p1 -i "${patchfile}" 2>&1 | tee -a ${logdir}/patch.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
    fi
    patch_list="$patch_list $patchfile"
  done
  echo "Done patching"
fi

if test "x$do_reconfigure" == "x1"
then
  cd ${srcdir}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi

  echo Reconfiguring in `pwd` | tee -a ${logdir}/reconfigure.log
  ./autogen.sh --prefix=${prefix} 2>&1 | tee -a ${logdir}/reconfigure.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
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

  lndir ${srcdir} . 2>&1 | tee -a ${logdir}/configure.log
  echo Configuring in `pwd` | tee -a ${logdir}/configure.log
  #CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" ${srcdir}/configure --prefix=${prefix} --enable-silent-rules --disable-poisoning --enable-gtk-doc --enable-docbook 2>&1 | tee -a ${logdir}/configure.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
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
  PKG_CONFIG_SHELL_IS_POSIX=1 PATH=${instdir}/${prefix}/bin:$PATH make -k check 2>&1 | tee -a ${logdir}/test.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
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
  for f in ${instdir}${prefix}/share/doc/${name}-*
  do
    mv -f -t ${instdir}${prefix}/share/doc/${name}/${ver} ${f}/*
    rm -rf ${f}
  done
  mkdir -p ${instdir}${prefix}/share/doc/${capname} 2>&1 | tee -a ${logdir}/fixinstall.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  cat ${pkgbuilddir}/${subsys}-${badname}.RELEASE_NOTES.in | sed -e 's/\${ver}/'${ver}'/' -e 's/\${rev}/'${rev}'/' -e 's/\${changelog}/'"${changelog}"'/' -e 's/\${date}/'"$(date)"'/' -e 's/\${dllver}/'${dllver}'/' -e 's/\${dllvercpp}/'${dllvercpp}'/' >${pkgbuilddir}/${subsys}-${badname}.RELEASE_NOTES
  cp ${pkgbuilddir}/${subsys}-${badname}.RELEASE_NOTES \
    ${instdir}${prefix}/share/doc/${capname}/${badname}-${ver}-${rev}-${subsys}.RELEASE_NOTES.txt 2>&1 | tee -a ${logdir}/fixinstall.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
fi

if test "x$do_pack" == "x1"
then
  rm -f ${logdir}/pack.log
  cd ${instdir}${prefix}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  echo Packing | tee -a ${logdir}/pack.log
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${BINPKG} ${BIN_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${DEVPKG} ${DEV_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${DOCPKG} ${DOC_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${LICPKG} ${LIC_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${DLLPKG} ${DLL_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${DLLCPPPKG} ${DLLCPP_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  cd ${pkgbuilddir}  && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
  tar cv --lzma --hard-dereference -f ${pkgbuilddir}/${SRCPKG} ${SRC_CONTENTS} 2>&1 | tee -a ${logdir}/pack.log && if ! test "x${PIPESTATUS[0]}" == "x0"; then fail $LINENO; fi
fi

echo "Done"
exit 0
