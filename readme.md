# Useful scripts

## Build dynamatic on EDA2 machine

```sh
bash fetch-and-build-dynamatic.sh
bash fetch-and-build-legacy-dynamatic.sh
```

Since the official branch is not always stable, we switch to our stable branch:

```sh
cd dynamatic
git checkout origin/iterative-buffer
bash ../mybuild.sh
```

## Run your first example 

```sh
source environment.sh
cd benchmarks/fir && bash ../../flow_test.sh
```
