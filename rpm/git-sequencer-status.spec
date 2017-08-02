#
# spec file for package par2cmdline
#
# Copyright (c) 2017 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

%define git_ver %{nil}

Name:           git-sequencer-status
Version:        1.1
Release:        0
Summary:        Git sequencer status is a Bash script to display the sequencer status
License:        GPL-3.0
Group:          Development/Tools/Version
Url:            https://github.com/nmorey/git-sequencer-status
Source:         %{name}-%{version}%{git_ver}.tar.bz2
BuildRequires:  git-core >= 2.0
BuildRequires:  bc
BuildRequires:  asciidoc
BuildRequires:  xmlto
Requires:       git-core >= 2.0
BuildArch:      noarch

%description
Several git commands (rebase, cherry-pick, am, revert) use the git sequencer
 when a list actions needs to be executed.
Althouth all the information is available in the git directory, it can be sometimes quite hard
 to find out where you are within your rebase.

This script prints a status of what was done and what is left to do.

It is largely inspired by what Magit prints in it status screen.

%prep
%setup -q -n %{name}-%{version}%{git_ver}

%build

%check
./travis/test.sh

%install
make install %{?_smp_mflags} PREFIX=%{buildroot}/%{_prefix} install

%files
%{_bindir}/git-sequencer-status
%{_mandir}/man1/git-sequencer-status*

%changelog

