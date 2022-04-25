# postiche

Generate unsound HTML from any Elm documentation metadata.

## Examples

Try:

```
$ elm reactor
```

Then navigate to `src/Example.elm`.


## Development

1.  Build worker

    ````bash
    $ pnpm make:elm
    ````

2.  Build executable

    ```bash
    $ pnpm bundle
    ```

3.  Try executable with:

    ```bash
    $ node ./bin/postiche <ELM_PACKAGE_NAME>
    ```