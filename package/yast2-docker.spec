#
# spec file for package yast2-services-manager
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
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


######################################################################
#
# IMPORTANT: Please do not change spec file in build service directly
#            Use https://github.com/yast/yast-cio repo
#
######################################################################

Name:           yast2-docker
Version:        3.1.0
Release:        0
BuildArch:      noarch

BuildRoot:      %{_tmppath}/%{name}-build
Source0:        %{name}-%{version}.tar.bz2

Requires:       yast2 >= 3.1.0
Requires:       yast2-ruby-bindings >= 1.2.0
Requires:       rubygem(docker-api)

BuildRequires:  update-desktop-files
BuildRequires:  yast2-devtools
BuildRequires:  yast2-ruby-bindings >= 1.2.0
BuildRequires:  yast2 >= 3.0.5
#for install task
BuildRequires:  rubygem(yast-rake)
# for tests
BuildRequires:  rubygem(rspec)
# for docker api
BuildRequires:  rubygem(docker-api)

Summary:        YaST2 - GUI for docker management
Group:          System/YaST
License:        GPL-2.0 or GPL-3.0
Url:            https://github.com/yast/yast-docker

%description
Provides easy to use GUI for running docker containers.

%prep
%setup -n %{name}-%{version}

%check
rake test:unit

%install
rake install DESTDIR="%{buildroot}"

%files
%defattr(-,root,root)
%{yast_dir}/clients/*.rb
%{yast_dir}/lib/ydocker
%{yast_desktopdir}/docker.desktop

%doc COPYING
