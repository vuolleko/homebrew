require 'formula'

class Ntfs3g < Formula
  homepage 'http://www.tuxera.com/community/ntfs-3g-download/'
  url 'http://tuxera.com/opensource/ntfs-3g_ntfsprogs-2013.1.13.tgz'
  sha1 '8c12b7644d90ae9fb8d0aca0d7ebd5f8fac2c818'

  depends_on 'pkg-config' => :build
  depends_on 'osxfuse'
  depends_on 'gettext'

  def patches
    # From macports:
    # http://trunk/dports/fuse/ntfs-3g/files/patch-configure.diff
    # Modify configure such that it does not modify the default PKG_CONFIG_PATH
    { :p0 => DATA }
  end

  def install
    # Workaround for hardcoded /sbin in ntfsprogs
    inreplace "ntfsprogs/Makefile.in", "/sbin", sbin

    ENV.append "LDFLAGS", "-lintl"
    args = ["--disable-debug",
            "--disable-dependency-tracking",
            "--prefix=#{prefix}",
            "--exec-prefix=#{prefix}",
            "--mandir=#{man}",
            "--with-fuse=external"]

    system "./configure", *args
    system "make"
    system "make install"

    # Install a script that can be used to enable automount
    File.open("#{sbin}/mount_ntfs", File::CREAT|File::TRUNC|File::RDWR, 0755) do |f|
      f.puts <<-EOS.undent
      #!/bin/bash

      VOLUME_NAME="${@:$#}"
      VOLUME_NAME=${VOLUME_NAME#/Volumes/}
      USER_ID=#{Process.uid}
      GROUP_ID=#{Process.gid}

      if [ `/usr/bin/stat -f %u /dev/console` -ne 0 ]; then
        USER_ID=`/usr/bin/stat -f %u /dev/console`
        GROUP_ID=`/usr/bin/stat -f %g /dev/console`
      fi

      #{opt_prefix}/bin/ntfs-3g \\
        -o volname="${VOLUME_NAME}" \\
        -o local \\
        -o negative_vncache \\
        -o auto_xattr \\
        -o auto_cache \\
        -o noatime \\
        -o windows_names \\
        -o user_xattr \\
        -o inherit \\
        -o uid=$USER_ID \\
        -o gid=$GROUP_ID \\
        -o allow_other \\
        "$@" >> /var/log/mount-ntfs-3g.log 2>&1

      exit $?;
      EOS
    end
  end
end

__END__
--- configure.orig	2011-08-02 19:13:55.000000000 -0400
+++ configure	2011-08-02 19:14:14.000000000 -0400
@@ -20530,9 +20530,6 @@
	test "x${PKG_CONFIG}" = "xno" && { { echo "$as_me:$LINENO: error: pkg-config wasn't found! Please install from your vendor, or see http://pkg-config.freedesktop.org/wiki/" >&5
 echo "$as_me: error: pkg-config wasn't found! Please install from your vendor, or see http://pkg-config.freedesktop.org/wiki/" >&2;}
    { (exit 1); exit 1; }; }
-	# Libraries often install their metadata .pc files in directories
-	# not searched by pkg-config. Let's workaround this.
-	export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:/lib/pkgconfig:/usr/lib/pkgconfig:/opt/gnome/lib/pkgconfig:/usr/share/pkgconfig:/usr/local/lib/pkgconfig:$prefix/lib/pkgconfig:/opt/gnome/share/pkgconfig:/usr/local/share/pkgconfig

 pkg_failed=no
 { echo "$as_me:$LINENO: checking for FUSE_MODULE" >&5
