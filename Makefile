# Makefile for building combined pagekite.py files.
export PYTHONPATH := .

BREED_PAGEKITE = pagekite/__init__.py \
	         pagekite/common.py \
	         pagekite/compat.py \
	         pagekite/logging.py \
	         pagekite/manual.py \
	         pagekite/proto/__init__.py \
	         pagekite/proto/proto.py \
	         pagekite/proto/parsers.py \
	         pagekite/proto/selectables.py \
	         pagekite/proto/filters.py \
	         pagekite/proto/conns.py \
	         pagekite/ui/__init__.py \
	         pagekite/ui/nullui.py \
	         pagekite/ui/basic.py \
	         pagekite/ui/remote.py \
	         pagekite/yamond.py \
	         pagekite/httpd.py \
	         pagekite/pk.py \


combined: pagekite tools doc/MANPAGE.md dev .header
	@./scripts/breeder.py --compress --header .header \
	             sockschain $(BREED_PAGEKITE) \
	             pagekite/__main__.py \
	             >pagekite-tmp.py
	@chmod +x pagekite-tmp.py
	@./scripts/blackbox-test.sh ./pagekite-tmp.py \
	        && ./scripts/blackbox-test.sh ./pagekite-tmp.py --nopyopenssl \
	        && ./scripts/blackbox-test.sh ./pagekite-tmp.py --nossl
	@killall pagekite-tmp.py
	@mv pagekite-tmp.py dist/pagekite-`python setup.py --version`.py
	@ls -l dist/pagekite-*.py

gtk: pagekite tools dev .header
	@./scripts/breeder.py --gtk-images --compress --header .header \
	             sockschain $(BREED_PAGEKITE) gui \
	             pagekite_gtk.py \
	             >pagekite-tmp.py
	@chmod +x pagekite-tmp.py
	@mv pagekite-tmp.py dist/pagekite-gtk-`python setup.py --version`.py
	@ls -l dist/pagekite-*.py

android: pagekite tools .header
	@./scripts/breeder.py --compress --header .header \
	             sockschain $(BREED_PAGEKITE) \
	             pagekite/android.py \
	             >pagekite-tmp.py
	@chmod +x pagekite-tmp.py
	@mv pagekite-tmp.py dist/pk-android-`./pagekite-tmp.py --appver`.py
	@ls -l dist/pk-android-*.py

doc/MANPAGE.md: pagekite pagekite/manual.py
	@./pagekite/manual.py --nopy --markdown >doc/MANPAGE.md

doc/pagekite.1: pagekite pagekite/manual.py
	@./pagekite/manual.py --nopy --man >doc/pagekite.1

dist: combined gtk allrpm android

allrpm: rpm_el4 rpm_el5 rpm_el6-fc13 rpm_fc14-15-16

alldeb: .deb

rpm_fc14-15-16:
	@./rpm/rpm-setup.sh 0pagekite_fc14fc15fc16 /usr/lib/python2.7/site-packages
	@make .rpm

rpm_el4:
	@./rpm/rpm-setup.sh 0pagekite_el4 /usr/lib/python2.3/site-packages
	@make .rpm

rpm_el5:
	@./rpm/rpm-setup.sh 0pagekite_el5 /usr/lib/python2.4/site-packages
	@make .rpm

rpm_el6-fc13:
	@./rpm/rpm-setup.sh 0pagekite_el6fc13 /usr/lib/python2.6/site-packages
	@make .rpm

.rpm: doc/pagekite.1
	@python setup.py bdist_rpm --install=rpm/rpm-install.sh \
	                           --post-install=rpm/rpm-post.sh \
	                           --pre-uninstall=rpm/rpm-preun.sh \
	                           --requires=python-SocksipyChain

VERSION=`python setup.py --version`
.debprep:
	@rm -f setup.cfg

.targz:
	@python setup.py sdist

.deb: .debprep
	@debuild -i -us -uc
	@mv ../pagekite_*.deb dist/

.header: pagekite doc/header.txt
	@sed -e "s/@VERSION@/$(VERSION)/g" \
		< doc/header.txt >.header

test: dev
	@./scripts/blackbox-test.sh ./pk
	@./scripts/blackbox-test.sh ./pk --nopyopenssl
	@./scripts/blackbox-test.sh ./pk --nossl

pagekite: pagekite/__init__.py pagekite/httpd.py pagekite/__main__.py

dev: sockschain
	@rm -f .SELF
	@ln -fs . .SELF
	@ln -fs scripts/pagekite_gtk pagekite_gtk.py
	@echo export PYTHONPATH=`pwd`
	@echo export HTTP_PROXY=
	@echo export http_proxy=

sockschain:
	@ln -fs ../PySocksipyChain/sockschain .

tools: scripts/breeder.py Makefile

scripts/breeder.py:
	@ln -fs ../../PyBreeder/breeder.py scripts/breeder.py

distclean: clean
	@rm -rvf dist/*.*

clean:
	@rm -vf sockschain *.pyc */*.pyc */*/*.pyc scripts/breeder.py .SELF
	@rm -vf .appver pagekite-tmp.py MANIFEST setup.cfg pagekite_gtk.py
	@rm -vrf *.egg-info .header doc/pagekite.1 build/
	-debuild clean

