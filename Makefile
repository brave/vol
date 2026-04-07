all: graph hadolint mypy README.md

# Output per target, use bash in recipes, fail on errors, be quiet by default

MAKEFLAGS := -rRO
SHELL := $(shell command -v bash)
.SHELLFLAGS := -eEo pipefail -c
.ONESHELL:
$(V).SILENT:
.PHONY: all clean docker graph hadolint mypy

# Update README.md

actions := none attach detach snapshot clean list

.INTERMEDIATE: $(actions:%=README.md.%)

$(actions:%=README.md.%): README.md.%:
	COLUMNS=110 ./vol $(*:none=) -h >"$@"

README.md: $(actions:%=README.md.%) vol $(MAKEFILE_LIST)
	end='^%$$'
	$(foreach action,$(actions),beg='^% vol $(action:none=)* -h$$'; sed -e "/$$beg/,/$$end/{ /$$beg/{p; r README.md.$(action)
	    }; /$$end/p; d }" -i "$@";)

clean:
	rm -f $(actions:%=README.md.%)

# Run mypy

mypy-venv: requirements.txt $(MAKEFILE_LIST)
	python3 -m venv mypy-venv
	source mypy-venv/bin/activate
	pip -q install -r requirements.txt
	pip -q install boto3 'boto3-stubs[essential]' mypy types-python-dateutil

mypy: mypy-venv
	source mypy-venv/bin/activate
	mypy vol

# Run hadolint

hadolint:
	hadolint Dockerfile

# Build the docker image

docker: hadolint
	read -ra maybe_sudo <<<"$$(id -nG|grep -qw 'docker\|root' || echo sudo)"
	"$${maybe_sudo[@]}" docker buildx build -t vol .

# Generate the graph for the README

graph: vol-attach.svg

vol-attach.svg: vol-attach.dot
	dot -Tsvg "$<" -o "$@"
