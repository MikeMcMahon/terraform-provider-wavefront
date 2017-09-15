TEST?=$$(go list ./... |grep -v 'vendor')
GOFMT_FILES?=$$(find . -name '*.go' |grep -v vendor)

default: build

build: fmtcheck
	go build -o terraform-provider-wavefront

fmtcheck:
	@sh -c "'$(CURDIR)/scripts/gofmtcheck.sh'"

fmt:
	gofmt -w $(GOFMT_FILES)

release:
	docker run --rm -v "$$PWD"\:/go/src/github.com/spaceapegames/terraform-provider-wavefront -w /go/src/github.com/spaceapegames/terraform-provider-wavefront golang\:1.8 make
	docker build -t go-code-release .
	mv terraform-provider-wavefront terraform-provider-wavefront_$(VERSION)
	docker run -v "$$PWD"\:/tmp -w /tmp -e GITHUB_TOKEN -e 'VERSION' -e 'BINARY' --rm go-code-release

vet:
	@echo "go vet ."
	@go vet $$(go list ./... | grep -v vendor/) ; if [ $$? -eq 1 ]; then \
		echo ""; \
		echo "Vet found suspicious constructs. Please check the reported constructs"; \
		echo "and fix them if necessary before submitting the code for review."; \
		exit 1; \
	fi

errcheck:
	@sh -c "'$(CURDIR)/scripts/errcheck.sh'"

vendor-status:
	@govendor status

test: fmtcheck
	go test -i $(TEST) || exit 1
	echo $(TEST) | \
		xargs -t -n4 go test $(TESTARGS) -timeout=30s -parallel=4

acceptance: fmtcheck
	go test -v -i $(TEST) || exit 1
	echo $(TEST) | \
		TF_ACC=true xargs -t -n4 go test -v $(TESTARGS) -parallel=4