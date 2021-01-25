# Some simple testing tasks (sorry, UNIX only).
.PHONY: all build flake test vtest cov clean doc mypy install dist sources srpm

PYXS = $(wildcard multidict/*.pyx)
SRC = multidict tests setup.py
PYTHON  = python
PROGRAM = multidict
PACKAGE = python-$(PROGRAM)
VERSION = $(shell sed -n s/[[:space:]]*Version:[[:space:]]*//p $(PACKAGE).spec)

all: build

.install-deps: $(shell find requirements -type f)
	pip install -r requirements/dev.txt
	@touch .install-deps

.flake: .install-deps $(shell find multidict -type f) \
                      $(shell find tests -type f)
	flake8 multidict tests
	@if ! isort -c -rc multidict tests; then \
            echo "Import sort errors, run 'make fmt' to fix them!!!"; \
            isort --diff -rc multidict tests; \
            false; \
	fi
	@touch .flake


isort-check:
	@if ! isort -c -rc $(SRC); then \
            echo "Import sort errors, run 'make fmt' to fix them!!!"; \
            isort --diff -c -rc $(SRC); \
            false; \
	fi

flake8:
	flake8 $(SRC)

black-check:
	@if ! isort -c -rc $(SRC); then \
            echo "black errors, run 'make fmt' to fix them!!!"; \
	    black -t py35 --diff --check $(SRC); \
            false; \
	fi

mypy:
	mypy multidict tests

lint: flake8 black-check mypy isort-check

fmt:
	black -t py35 $(SRC)
	isort -rc $(SRC)

check_changes:
	./tools/check_changes.py

.develop: .install-deps $(shell find multidict -type f) .flake check_changes mypy
	pip install -e .
	@touch .develop

test: .develop
	@pytest -q

vtest: .develop
	@pytest -s -v

cov-dev: .develop
	@pytest --cov-report=html
	@echo "open file://`pwd`/htmlcov/index.html"

cov-ci-run: .develop
	@echo "Regular run"
	@pytest --cov-report=html

cov-dev-full: cov-ci-run
	@echo "open file://`pwd`/htmlcov/index.html"

doc:
	@make -C docs html SPHINXOPTS="-W -E"
	@echo "open file://`pwd`/docs/_build/html/index.html"

doc-spelling:
	@make -C docs spelling SPHINXOPTS="-W -E"

install:
	$(PYTHON) setup.py install --skip-build

install-dev: .develop

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
	rm -f multidict/*.html
	rm -f multidict/*.so
	rm -f multidict/*.pyd
	rm -rf .tox
