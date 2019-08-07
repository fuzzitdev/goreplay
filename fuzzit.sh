set -xe

## go-fuzz doesn't support modules for now, so ensure we do everything
## in the old style GOPATH way
export GO111MODULE="off"

if [ -z ${1+x} ]; then
    echo "must call with job type as first argument e.g. 'fuzzing' or 'sanity'"
    echo "see https://github.com/fuzzitdev/example-go/blob/master/.travis.yml"
    exit 1
fi

# Note: this is temporary api key for https://app.fuzzit.dev/orgs/goreplay
# account. It'll be deleted after PR is merged and new key will
# have to be generated by the owner of the account and set in CI settings
# as it must be kept secret
export FUZZIT_API_KEY=19060041f7d869e9f2367cfe4e6680a437d55759cebfbe1b0193aca20257ba4c90dcf261512cbf50f6489d62d878db6a

if [ -z "${FUZZIT_API_KEY}" ]; then
    echo "Please set env variable FUZZIT_API_KEY to api key for your project"
    echo "API KEY for goreplay: https://app.fuzzit.dev/orgs/goreplay/settings"
    exit 1
fi

## Install go-fuzz
go get -u github.com/dvyukov/go-fuzz/go-fuzz github.com/dvyukov/go-fuzz/go-fuzz-build

TARGET="proto-fuzzer"

## build fuzz target
go-fuzz-build -libfuzzer -o ${TARGET}.a ./proto
clang -fsanitize=fuzzer ${TARGET}.a -o ${TARGET}

wget -q -O fuzzit https://github.com/fuzzitdev/fuzzit/releases/download/v2.4.11/fuzzit_Linux_x86_64
chmod a+x fuzzit
./fuzzit auth ${FUZZIT_API_KEY}

# create fuzzing target on the server if it doesn't already exist
./fuzzit create target ${TARGET} || true

if [ $1 == "fuzzing" ]; then
    ./fuzzit create job --branch $TRAVIS_BRANCH --revision $TRAVIS_COMMIT ${TARGET} "./${TARGET}"
else
    ./fuzzit create job --local ${TARGET} "./${TARGET}"
fi
