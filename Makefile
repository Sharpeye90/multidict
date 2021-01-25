# Some simple testing tasks (sorry, UNIX only).
.PHONY: all build flake test vtest cov clean doc mypy install dist sources srpm

PYXS = $(wildcard multidict/*.pyx)
SRC = multidict tests setup.py
PYTHON  = python
PROGRAM = multidict
PACKAGE = python-$(PROGRAM)
VERSION = $(shell sed -n s/[[:space:]]*Version:[[:space:]]*//p $(PACKAGE).spec)

all: build


install:
	$(PYTHON) setup.py install --skip-build

cov-dev: mypy
	tox -e profile-dev -- --cov-report=html
	@which xdg-open 2>/dev/null 1>&2 && export opener=xdg-open || export opener=open && \
	$${opener} "file://`pwd`/htmlcov/index.html"

cov-dev-full: mypy
	MULTIDICT_NO_EXTENSIONS=1 tox -e profile-dev -- --cov-report=html
	tox -e profile-dev -- --cov-report=html
	@which xdg-open 2>/dev/null 1>&2 && export opener=xdg-open || export opener=open && \
	$${opener} "file://`pwd`/htmlcov/index.html"

build:
	$(PYTHON) setup.py build

dist: clean
	$(PYTHON) setup.py sdist

sources: clean
	@git archive --format=tar --prefix="$(PROGRAM)-$(VERSION)/" \
		$(shell git rev-parse --verify HEAD) | gzip > "$(PROGRAM)-$(VERSION).tar.gz"

srpm: sources
	rpmbuild -bs --define "_sourcedir $(CURDIR)" \
		--define "_srcrpmdir $(CURDIR)" $(PACKAGE).spec
clean:
	rm -rf `find . -name __pycache__`
	rm -f `find . -type f -name '*.py[co]' `
	rm -f `find . -type f -name '*~' `
	rm -f `find . -type f -name '.*~' `
	rm -f `find . -type f -name '@*' `
	rm -f `find . -type f -name '#*#' `
	rm -f `find . -type f -name '*.orig' `
	rm -f `find . -type f -name '*.rej' `
	rm -f .coverage
	rm -rf coverage
	rm -rf build dist $(PROGRAM).egg-info $(PROGRAM)-*.tar.gz *.egg *.src.rpm
	rm -rf cover
	rm -rf htmlcov
	make -C docs clean SPHINXBUILD=false
	rm -f multidict/_multidict.html
	rm -f multidict/_multidict.c
	rm -f multidict/_multidict.*.so
	rm -f multidict/_multidict.*.pyd
	rm -f multidict/_istr.*.so
	rm -f multidict/_istr.*.pyd
	rm -f multidict/_pair_list.*.so
	rm -f multidict/_pair_list.*.pyd
	rm -f multidict/_multidict_iter.*.so
	rm -f multidict/_multidict_iter.*.pyd
	rm -f multidict/*.html
	rm -f multidict/*.so
	rm -f multidict/*.pyd
	rm -rf .tox

doc:
	tox -e doc-html
	@which xdg-open 2>/dev/null 1>&2 && export opener=xdg-open || export opener=open && \
	$${opener} "file://`pwd`/docs/_build/html/index.html"

doc-spelling:
	tox -e doc-spelling

install:
	pip install -U tox
	pip install -U pip
	pip install -Ur requirements/dev.txt
