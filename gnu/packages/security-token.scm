;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Mike Gerwitz <mtg@gnu.org>
;;; Copyright © 2016 Marius Bakke <mbakke@fastmail.com>
;;; Copyright © 2017 Thomas Danckaert <post@thomasdanckaert.be>
;;; Copyright © 2017–2021 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2017, 2019 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2018, 2019 Chris Marusich <cmmarusich@gmail.com>
;;; Copyright © 2018 Arun Isaac <arunisaac@systemreboot.net>
;;; Copyright © 2020 Raphaël Mélotte <raphael.melotte@mind.be>
;;; Copyright © 2021 Antero Mejr <antero@kodmin.com>
;;; Copyright © 2021 Sergey Trofimov <sarg@sarg.org.ru>
;;; Copyright © 2021 Dhruvin Gandhi <contact@dhruvin.dev>
;;; Copyright © 2021 Ahmad Jarara <git@ajarara.io>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages security-token)
  #:use-module (gnu packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (guix build-system python)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages crates-io)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages dns)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages libbsd)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages man)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages cyrus-sasl)
  #:use-module (gnu packages popt)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages tex)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages swig)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xml))

(define-public ccid
  (package
    (name "ccid")
    (version "1.4.36")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://ccid.apdu.fr/files/ccid-"
                                  version ".tar.bz2"))
              (sha256
               (base32
                "1ha9cwxkadx4rs4jj114qzh42qj02x6r8y1mvhcvijhvby4aqwrb"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags (list (string-append "--enable-usbdropdir=" %output
                                              "/pcsc/drivers"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-Makefile
           (lambda _
             (substitute* "src/Makefile.in"
               (("/bin/echo") (which "echo")))
             #t)))))
    (native-inputs
     `(("perl" ,perl)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("libusb" ,libusb)
       ("pcsc-lite" ,pcsc-lite)))
    (home-page "https://ccid.apdu.fr/")
    (synopsis "PC/SC driver for USB smart card devices")
    (description
     "This package provides a PC/SC IFD handler implementation for devices
compliant with the CCID and ICCD protocols.  It supports a wide range of
readers and is needed to communicate with such devices through the
@command{pcscd} resource manager.")
    (license license:lgpl2.1+)))

(define-public eid-mw
  (package
    (name "eid-mw")
    ;; When updating, remove the short-lived libbsd input and module import!
    (version "5.0.28")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Fedict/eid-mw")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0fmpdx09a60ndbsvy3m6w77naqy3j6k2ydq6jdcmdvxnr31z7fmf"))))
    (build-system glib-or-gtk-build-system)
    (native-inputs
     `(("autoconf" ,autoconf)
       ("autoconf-archive" ,autoconf-archive)
       ("automake" ,automake)
       ("gettext" ,gettext-minimal)
       ("libtool" ,libtool)
       ("libassuan" ,libassuan)
       ("pkg-config" ,pkg-config)
       ("perl" ,perl)))
    (inputs
     `(("curl" ,curl)
       ("libbsd" ,libbsd)
       ("openssl" ,openssl)
       ("gtk+" ,gtk+)
       ("pcsc-lite" ,pcsc-lite)
       ("p11-kit" ,p11-kit)
       ("libproxy" ,libproxy)
       ("libxml2" ,libxml2)
       ("cyrus-sasl" ,cyrus-sasl)))
    (arguments
     `(#:configure-flags
       (list "--disable-static"

             ;; With the (prettier) pinentry enabled, eid-viewer will skip
             ;; crucial dialogue when used with card readers with built-in
             ;; keypads such as the Digipass 870, and possibly others too.
             "--disable-pinentry")
       #:phases
       (modify-phases %standard-phases
         (replace 'bootstrap
           (lambda _
             ;; configure.ac relies on ‘git --describe’ to get the version.
             ;; Patch it to just return the real version number directly.
             (substitute* "scripts/build-aux/genver.sh"
               (("/bin/sh") (which "sh"))
               (("^(GITDESC=).*" _ match) (string-append match ,version "\n")))
             (invoke "sh" "./bootstrap.sh"))))))
    (synopsis "Belgian electronic identity card (eID) middleware")
    (description "The Belgian eID middleware is required to authenticate with
online services and sign digital documents with Belgian identity cards.

It requires a running pcscd service and a compatible card reader.")
    (home-page "https://github.com/Fedict/eid-mw")
    (license license:lgpl3)))

(define-public libyubikey
  (package
    (name "libyubikey")
    (version "1.13")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://developers.yubico.com/yubico-c/Releases/"
                    name "-" version ".tar.gz"))
              (sha256
               (base32
                "009l3k2zyn06dbrlja2d4p2vfnzjhlcqxi88v02mlrnb17mx1v84"))))
    (build-system gnu-build-system)
    (synopsis "Development kit for the YubiKey authentication device")
    (description
     "This package contains a C library and command-line tools that make up
the low-level development kit for the Yubico YubiKey authentication device.")
    (home-page "https://developers.yubico.com/yubico-c/")
    (license license:bsd-2)))

(define-public softhsm
  (package
    (name "softhsm")
    (version "2.6.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://dist.opendnssec.org/source/"
                    "softhsm-" version ".tar.gz"))
              (sha256
               (base32
                "1wkmyi6n3z2pak1cj5yk6v6bv9w0m24skycya48iikab0mrr8931"))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags '("--disable-gost"))) ; TODO Missing the OpenSSL
                                               ; engine for GOST
    (inputs
     `(("openssl" ,openssl)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("cppunit" ,cppunit)))
    (synopsis "Software implementation of a generic cryptographic device")
    (description
     "SoftHSM 2 is a software implementation of a generic cryptographic device
with a PKCS #11 Cryptographic Token Interface.")
    (home-page "https://www.opendnssec.org/softhsm/")
    (license license:bsd-2)))

(define-public pcsc-lite
  (package
    (name "pcsc-lite")
    (version "1.9.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://pcsclite.apdu.fr/files/"
                                  "pcsc-lite-" version ".tar.bz2"))
              (sha256
               (base32
                "1y9f9zipnrmgiw0mxrvcgky8vfrcmg6zh40gbln5a93i2c1x8j01"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags '("--enable-usbdropdir=/var/lib/pcsc/drivers"
                           "--disable-libsystemd")))
    (native-inputs
     `(("perl" ,perl)                   ; for pod2man
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("libudev" ,eudev)))
    (home-page "https://pcsclite.apdu.fr/")
    (synopsis "Middleware to access a smart card using PC/SC")
    (description
     "pcsc-lite provides an interface to communicate with smartcards and
readers using the SCard API.  pcsc-lite is used to connect to the PC/SC daemon
from a client application and provide access to the desired reader.")
    (license (list license:bsd-3                ; pcsc-lite
                   license:isc                  ; src/strlcat.c src/strlcpy.c
                   license:gpl3+))))            ; src/spy/*

(define-public ykclient
  (package
    (name "ykclient")
    (version "2.15")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://developers.yubico.com/yubico-c-client/Releases/"
                    name "-" version ".tar.gz"))
              (sha256
               (base32
                "05jhx9waj3pl120ddnwap1v3bjrnbfhvf3lxs2xmhpcmwzpwsqgl"))))
    (build-system gnu-build-system)

    ;; There's just one test, and it requires network access to access
    ;; yubico.com, so skip it.
    (arguments '(#:tests? #f))

    (native-inputs `(("pkg-config" ,pkg-config)
                     ("help2man" ,help2man)))
    (inputs `(("curl" ,curl)))
    (synopsis "C library to validate one-time-password YubiKeys")
    (description
     "YubiKey C Client Library (libykclient) is a C library used to validate a
one-time-password (OTP) YubiKey against Yubico’s servers.  See the Yubico
website for more information about Yubico and the YubiKey.")
    (home-page "https://developers.yubico.com/yubico-c-client/")
    (license license:bsd-2)))

(define-public opensc
  (package
    (name "opensc")
    (version "0.21.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/OpenSC/OpenSC/releases/download/"
                    version "/opensc-" version ".tar.gz"))
              (sha256
               (base32
                "0pijycjwpll9zn83dazgsh8n9ywq0z1ragjsd1sqv3abrcfvpyrb"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         ;; By setting an absolute path here, we arrange for OpenSC to
         ;; successfully dlopen libpcsclite.so.1 by default.  The user can
         ;; still override this if they want to, by specifying a custom OpenSC
         ;; configuration file at runtime.
         (add-after 'unpack 'set-default-libpcsclite.so.1-path
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((libpcsclite (string-append (assoc-ref inputs "pcsc-lite")
                                               "/lib/libpcsclite.so.1")))
               (substitute* "configure"
                 (("DEFAULT_PCSC_PROVIDER=\"libpcsclite\\.so\\.1\"")
                  (string-append
                   "DEFAULT_PCSC_PROVIDER=\"" libpcsclite "\"")))
               #t))))))
    (inputs
     `(("readline" ,readline)
       ("openssl" ,openssl)
       ("pcsc-lite" ,pcsc-lite)
       ("ccid" ,ccid)))
    (native-inputs
     `(("libxslt" ,libxslt)
       ("docbook-xsl" ,docbook-xsl)
       ("pkg-config" ,pkg-config)))
    (home-page "https://github.com/OpenSC/OpenSC/wiki")
    (synopsis "Tools and libraries related to smart cards")
    (description
     "OpenSC is a set of software tools and libraries to work with smart
cards, with the focus on smart cards with cryptographic capabilities.  OpenSC
facilitate the use of smart cards in security applications such as
authentication, encryption and digital signatures.  OpenSC implements the PKCS
#15 standard and the PKCS #11 API.")
    (license license:lgpl2.1+)))

(define-public yubico-piv-tool
  (package
    (name "yubico-piv-tool")
    (version "1.6.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://developers.yubico.com/yubico-piv-tool/Releases/"
                    name "-" version ".tar.gz"))
              (sha256
               (base32
                "10xgdc51xvszkxmsvqnbjs8ixxz7rfnfahh3wn8glllynmszbhwi"))))
    (build-system gnu-build-system)
    (inputs
     `(("gengetopt" ,gengetopt)
       ("perl" ,perl)
       ("pcsc-lite" ,pcsc-lite)
       ("openssl" ,openssl)))
    (native-inputs
     `(("doxygen" ,doxygen)
       ("graphviz" ,graphviz)
       ("help2man" ,help2man)
       ("check" ,check)
       ("texlive-bin" ,texlive-bin)
       ("pkg-config" ,pkg-config)))
    (home-page "https://developers.yubico.com/yubico-piv-tool/")
    (synopsis "Interact with the PIV application on a YubiKey")
    (description
     "The Yubico PIV tool is used for interacting with the Privilege and
Identification Card (PIV) application on a YubiKey.  With it you may generate
keys on the device, import keys and certificates, create certificate requests,
and other operations.  It includes a library and a command-line tool.")
    ;; The file ykcs11/pkcs11.h also declares an additional, very short free
    ;; license for that one file.  Please see it for details.  The vast
    ;; majority of files are licensed under bsd-2.
    (license license:bsd-2)))

(define-public yubikey-personalization
  (package
    (name "yubikey-personalization")
    (version "1.20.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://developers.yubico.com/" name
                    "/Releases/ykpers-" version ".tar.gz"))
              (sha256
               (base32
                "14wvlwqnwj0gllkpvfqiy8ns938bwvjsz8x1hmymmx32m074vj0f"))
              (modules '((guix build utils)))
              (snippet
               ;; Fix build with GCC 10, remove for versions > 1.20.0.
               '(begin
                  (substitute* "ykpers-args.h"
                    (("^const char")
                     "extern const char"))))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags (list (string-append "--with-udevrulesdir="
                                              (assoc-ref %outputs "out")
                                              "/lib/udev/rules.d"))))
    (inputs
     `(("json-c" ,json-c-0.13)
       ("libusb" ,libusb)
       ;; The library "libyubikey" is also known as "yubico-c".
       ("libyubikey" ,libyubikey)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("eudev" ,eudev)))
    (home-page "https://developers.yubico.com/yubikey-personalization/")
    (synopsis "Library and tools to personalize YubiKeys")
    (description
     "The YubiKey Personalization package contains a C library and command
line tools for personalizing YubiKeys.  You can use these to set an AES key,
retrieve a YubiKey's serial number, and so forth.")
    (license license:bsd-2)))

(define-public python-pyscard
  (package
    (name "python-pyscard")
    (version "1.9.9")
    (source (origin
              (method url-fetch)
              ;; The maintainer publishes releases on various sites, but
              ;; SourceForge is apparently the only one with a signed release.
              (uri (string-append
                    "mirror://sourceforge/pyscard/pyscard/pyscard%20"
                    version "/pyscard-" version ".tar.gz"))
              (sha256
               (base32
                "082cjkbxadaz2jb4rbhr0mkrirzlqyqhcf3r823qb0q1k50ybgg6"))))
    (build-system python-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         ;; Tell pyscard where to find the PCSC include directory.
         (add-after 'unpack 'patch-platform-include-dirs
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((pcsc-include-dir (string-append
                                      (assoc-ref inputs "pcsc-lite")
                                      "/include/PCSC")))
               (substitute* "setup.py"
                 (("platform_include_dirs = \\[.*?\\]")
                  (string-append
                   "platform_include_dirs = ['" pcsc-include-dir "']")))
               #t)))
         ;; pyscard wants to dlopen libpcsclite, so tell it where it is.
         (add-after 'unpack 'patch-dlopen
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* "smartcard/scard/winscarddll.c"
               (("lib = \"libpcsclite\\.so\\.1\";")
                (simple-format #f
                               "lib = \"~a\";"
                               (string-append (assoc-ref inputs "pcsc-lite")
                                              "/lib/libpcsclite.so.1"))))
             #t)))))
    (inputs
     `(("pcsc-lite" ,pcsc-lite)))
    (native-inputs
     `(("swig" ,swig)))
    (home-page "https://github.com/LudovicRousseau/pyscard")
    (synopsis "Smart card library for Python")
    (description
     "The pyscard smart card library is a framework for building smart card
aware applications in Python.  The smart card module is built on top of the
PCSC API Python wrapper module.")
    (license license:lgpl2.1+)))

(define-public python2-pyscard
  (package-with-python2 python-pyscard))

(define-public libu2f-host
  (package
    (name "libu2f-host")
    (version "1.1.10")
    (source (origin
              (method url-fetch)
              (uri
               (string-append
                "https://developers.yubico.com"
                "/libu2f-host/Releases/libu2f-host-" version ".tar.xz"))
              (sha256
               (base32
                "0vrivl1dwql6nfi48z6dy56fwy2z13d7abgahgrs2mcmqng7hra2"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags
       (list "--enable-gtk-doc"
             (string-append "--with-udevrulesdir="
                            (assoc-ref %outputs "out")
                            "/lib/udev/rules.d"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-docbook-xml
           (lambda* (#:key inputs #:allow-other-keys)
             ;; Avoid a network connection attempt during the build.
             (substitute* "gtk-doc/u2f-host-docs.xml"
               (("http://www.oasis-open.org/docbook/xml/4.3/docbookx.dtd")
                (string-append (assoc-ref inputs "docbook-xml")
                               "/xml/dtd/docbook/docbookx.dtd")))
             #t)))))
    (inputs
     `(("json-c" ,json-c-0.13)
       ("hidapi" ,hidapi)))
    (native-inputs
     `(("help2man" ,help2man)
       ("gengetopt" ,gengetopt)
       ("pkg-config" ,pkg-config)
       ("gtk-doc" ,gtk-doc)
       ("docbook-xml" ,docbook-xml-4.3)
       ("eudev" ,eudev)))
    (home-page "https://developers.yubico.com/libu2f-host/")
    ;; TRANSLATORS: The U2F protocol has a "server side" and a "host side".
    (synopsis "U2F host-side C library and tool")
    (description
     "Libu2f-host provides a C library and command-line tool that implements
the host-side of the Universal 2nd Factor (U2F) protocol.  There are APIs to
talk to a U2F device and perform the U2F Register and U2F Authenticate
operations.")
    ;; Most files are LGPLv2.1+, but some files are GPLv3+.
    (license (list license:lgpl2.1+ license:gpl3+))))

(define-public libu2f-server
  (package
    (name "libu2f-server")
    (version "1.1.0")
    (source (origin
              (method git-fetch)
              (uri
               (git-reference
                (url "https://github.com/Yubico/libu2f-server")
                (commit (string-append "libu2f-server-" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1nmsfq372zza5y6j13ydincjf324bwfcjg950vykh166xkp6wiic"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags
       (list "--enable-gtk-doc"
             "--enable-tests")))
    (inputs
     `(("json-c" ,json-c-0.13)
       ("libressl" ,libressl)))
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("libtool" ,libtool)
       ("check" ,check)
       ("gengetopt" ,gengetopt)
       ("help2man" ,help2man)
       ("pkg-config" ,pkg-config)
       ("gtk-doc" ,gtk-doc)
       ("which" ,which)))
    (home-page "https://developers.yubico.com/libu2f-server/")
    ;; TRANSLATORS: The U2F protocol has a "server side" and a "host side".
    (synopsis "U2F server-side C library")
    (description
     "This is a C library that implements the server-side of the
@dfn{Universal 2nd Factor} (U2F) protocol.  More precisely, it provides an API
for generating the JSON blobs required by U2F devices to perform the U2F
Registration and U2F Authentication operations, and functionality for
verifying the cryptographic operations.")
    (license license:bsd-2)))

(define-public pam-u2f
  (package
    (name "pam-u2f")
    (version "1.0.8")
    (source (origin
              (method git-fetch)
              (uri
               (git-reference
                (url "https://github.com/Yubico/pam-u2f")
                (commit (string-append "pam_u2f-" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "04d9davyi33gqbvga1rvh9fijp6f16mx2xmnn4n61rnhcn2jac98"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags
       (list (string-append "--with-pam-dir="
                            (assoc-ref %outputs "out") "/lib/security"))))
    (inputs
     `(("libu2f-host" ,libu2f-host)
       ("libu2f-server" ,libu2f-server)
       ("linux-pam" ,linux-pam)))
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)
       ("libtool" ,libtool)
       ("asciidoc" ,asciidoc)
       ("pkg-config" ,pkg-config)))
    (home-page "https://developers.yubico.com/pam-u2f/")
    (synopsis "PAM module for U2F authentication")
    (description
     "This package provides a module implementing PAM over U2F, providing an
easy way to integrate the YubiKey (or other U2F compliant authenticators) into
your existing infrastructure.")
    (license license:bsd-2)))

(define-public python-fido2
  (package
    (name "python-fido2")
    (version "0.5.0")
    (source (origin
              (method url-fetch)
              (uri
               (string-append
                "https://github.com/Yubico/python-fido2/releases/download/"
                version "/fido2-" version ".tar.gz"))
              (sha256
               (base32
                "1pl8d2pr6jzqj4y9qiaddhjgnl92kikjxy0bgzm2jshkzzic8mp3"))
              (snippet
               ;; Remove bundled dependency.
               #~(delete-file "fido2/public_suffix_list.dat"))))
    (build-system python-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'install-public-suffix-list
           (lambda* (#:key inputs #:allow-other-keys)
             (copy-file
              (string-append (assoc-ref inputs "public-suffix-list")
                             "/share/public-suffix-list-"
                             ,(package-version public-suffix-list)
                             "/public_suffix_list.dat")
              "fido2/public_suffix_list.dat")
             #t)))))
    (propagated-inputs
     `(("python-cryptography" ,python-cryptography)
       ("python-six" ,python-six)))
    (native-inputs
     `(("python-mock" ,python-mock)
       ("python-pyfakefs" ,python-pyfakefs)
       ("public-suffix-list" ,public-suffix-list)))
    (home-page "https://github.com/Yubico/python-fido2")
    (synopsis "Python library for communicating with FIDO devices over USB")
    (description
     "This Python library provides functionality for communicating with a Fast
IDentity Online (FIDO) device over Universal Serial Bus (USB) as well as
verifying attestation and assertion signatures.  It aims to support the FIDO
Universal 2nd Factor (U2F) and FIDO 2.0 protocols for communicating with a USB
authenticator via the Client-to-Authenticator Protocol (CTAP 1 and 2).  In
addition to this low-level device access, classes defined in the
@code{fido2.client} and @code{fido2.server} modules implement higher level
operations which are useful when interfacing with an Authenticator, or when
implementing a Relying Party.")
    ;; python-fido2 contains some derivative files originally from pyu2f
    ;; (https://github.com/google/pyu2f).  These files are licensed under the
    ;; Apache License, version 2.0.  The maintainers have customized these
    ;; files for internal use, so they are not really a bundled dependency.
    (license (list license:bsd-2 license:asl2.0))))

(define-public python-yubikey-manager
  (package
    (name "python-yubikey-manager")
    (version "2.1.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://developers.yubico.com/yubikey-manager/Releases"
                    "/yubikey-manager-" version ".tar.gz"))
              (sha256
               (base32
                "11rsmcaj60k3y5m5gdhr2nbbz0w5dm3m04klyxz0fh5hnpcmr7fm"))))
    (build-system python-build-system)
    (arguments
     '(#:modules ((srfi srfi-1)
                  (guix build utils)
                  (guix build python-build-system))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-libykpers-reference
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* "ykman/driver_otp.py"
               (("Ykpers\\('ykpers-1', '1'\\)")
                (string-append
                 "Ykpers('"
                 (find (negate symbolic-link?)
                       (find-files (assoc-ref inputs "yubikey-personalization")
                                   "^libykpers-.*\\.so\\..*"))
                 "')")))
             #t)))))
    (propagated-inputs
     `(("python-six" ,python-six)
       ("python-pyscard" ,python-pyscard)
       ("python-pyusb" ,python-pyusb)
       ("python-click" ,python-click)
       ("python-cryptography" ,python-cryptography)
       ("python-pyopenssl" ,python-pyopenssl)
       ("python-fido2" ,python-fido2)))
    (inputs
     `(("yubikey-personalization" ,yubikey-personalization)
       ("pcsc-lite" ,pcsc-lite)
       ("libusb" ,libusb)))
    (native-inputs
     `(("swig" ,swig)
       ("python-mock" ,python-mock)))
    (home-page "https://developers.yubico.com/yubikey-manager/")
    (synopsis "Command line tool and library for configuring a YubiKey")
    (description
     "Python library and command line tool for configuring a YubiKey.  Note
that after installing this package, you might still need to add appropriate
udev rules to your system configuration to be able to configure the YubiKey as
an unprivileged user.")
    (license license:bsd-2)))

(define-public nitrocli
  (package
    (name "nitrocli")
    (version "0.4.1")
    (source (origin
              (method url-fetch)
              (uri (crate-uri "nitrocli" version))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1djspfvcqjipg17v8hkph8xrhkdg1xqjhq5jk1sr8vr750yavidy"))))
    (build-system cargo-build-system)
    (arguments
     `(#:tests? #f ;; 2/164 tests fail, nitrocli-ext tests failing
       #:cargo-inputs
       (("rust-anyhow" ,rust-anyhow-1)
        ("rust-base32" ,rust-base32-0.4)
        ("rust-directories" ,rust-directories-3)
        ("rust-envy" ,rust-envy-0.4)
        ("rust-libc-0.2" ,rust-libc-0.2)
        ("rust-merge" ,rust-merge-0.1)
        ("rust-nitrokey" ,rust-nitrokey-0.9)
        ("rust-progressing" ,rust-progressing-3)
        ("rust-serde" ,rust-serde-1)
        ("rust-structopt" ,rust-structopt-0.3)
        ("rust-termion" ,rust-termion-1)
        ("rust-toml" ,rust-toml-0.5))
       #:cargo-development-inputs
       (("rust-nitrokey-test" ,rust-nitrokey-test-0.5)
        ("rust-nitrokey-test-state" ,rust-nitrokey-test-state-0.1)
        ("rust-regex" ,rust-regex-1)
        ("rust-tempfile" ,rust-tempfile-3))))
    (inputs
     `(("hidapi" ,hidapi)
       ("gnupg" ,gnupg)))
    (home-page "https://github.com/d-e-s-o/nitrocli")
    (synopsis "Command line tool for Nitrokey devices")
    (description
     "nitrocli is a program that provides a command line interface
for interaction with Nitrokey Pro, Nitrokey Storage, and Librem Key
devices.")
    (license license:gpl3+)))

(define-public ausweisapp2
  (package
    (name "ausweisapp2")
    (version "1.22.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/Governikus/AusweisApp2/releases"
                                  "/download/" version "/AusweisApp2-" version ".tar.gz"))
              (sha256
               (base32
                "1qh1m057va7njs3yk0s31kwsvv44fjlsdac6lhiw5npcwssgjn8l"))))

    (build-system cmake-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("qttools" ,qttools)))
    (inputs
     `(("qtbase" ,qtbase-5)
       ("qtsvg" ,qtsvg)
       ("qtdeclarative" ,qtdeclarative)
       ("qtwebsockets" ,qtwebsockets)
       ("qtgraphicaleffects" ,qtgraphicaleffects)
       ("qtquickcontrols2" ,qtquickcontrols2)
       ("pcsc-lite" ,pcsc-lite)
       ("openssl" ,openssl)))
    (arguments
     `(#:modules ((guix build cmake-build-system)
                  (guix build qt-utils)
                  (guix build utils))
       #:imported-modules (,@%cmake-build-system-modules
                           (guix build qt-utils))
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'wrap-qt
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (wrap-qt-program "AusweisApp2" #:output out #:inputs inputs)))))))
    (home-page "https://github.com/Governikus/AusweisApp2")
    (synopsis
     "Authentication program for German ID cards and residence permits")
    (description
     "This application is developed and issued by the German government to be
used for online authentication with electronic German ID cards and residence
titles.  To use this app, a supported RFID card reader or NFC-enabled smart
phone is required.")
    (license license:eupl1.2)))

(define-public libfido2
  (package
    (name "libfido2")
    (version "1.9.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "git://github.com/Yubico/libfido2")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256 (base32 "12zy4cnlcffcb64lsx8198y09j1dwi0bcn9rr82q6i1k950yzd3p"))))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (inputs
     `(("zlib" ,zlib)
       ("udev" ,eudev)
       ("libcbor" ,libcbor)
       ("openssl" ,openssl)))
    (build-system cmake-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         ;; regress tests enabled only for debug builds
         (delete 'check))))
    (synopsis "Library functionality and command-line tools for FIDO devices")
    (description "libfido2 provides library functionality and command-line
tools to communicate with a FIDO device over USB, and to verify attestation
and assertion signatures.

libfido2 supports the FIDO U2F (CTAP 1) and FIDO 2.0 (CTAP 2) protocols.")
    (license license:bsd-2)
    (home-page "https://github.com/Yubico/libfido2")))
