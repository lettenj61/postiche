# postiche

Generate unsound HTML from any Elm documentation metadata.

## About

`postiche` is a command line tool which takes Elm's documentation metadata (`docs.json`) as input and generate a set of HTML and Markdown files to host the doc elsewhere.

It uses [docsify](https://docsify.js.org/) to render contents.


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
$ node ./bin/postiche --help
Options:
    --help     Show help                                             [boolean]
    --version  Show version number                                   [boolean]
-o, --output   where to generate HTML into                            [string]
-p, --spec     package specification, <author>/<package>              [string]
    --docs     path of JSON file contains document info               [string]
```

### Example usage

```bash
$ node ./bin/postiche --spec elm/core --docs docs.json
```

## License

MIT