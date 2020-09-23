# Compiler for ugo language
## Step
* generate mycompiler by command
```
make
```
* Run your compiler by command which is built by lexand yacc, with the given μGO code (.go file) to generate the corresponding Java assemblycode (.j file)
```
./mycompiler < input.go
```
* Generate Main.class
```
java -jar jasmin.jar hw3.j
```
* Run Main
```
java Main
```