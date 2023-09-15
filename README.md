# Minion: Minimalist CLI wrapper for ChatGPT 👾

## The easiest and most lightweight way for developers to use ChatGPT in a CLI.

Minion is a simple CLI wrapper that calls OpenAI APIs with prefabbed prompts and your Git diff data. It expedites proactive - rather than reactive - code reviews, commit messaging, and test generation.

## What to know

This solution uses cURL to call OpenAI APIs. OpenAI will not train their models based on API calls, so this is a "safer" solution than, for example, using the web version.

## Prerequisites

You will need an [OpenAI API key](https://help.openai.com/en/articles/4936850-where-do-i-find-my-secret-api-key) and have it exported in the environment as `OPENAI_API_KEY`, i.e. run `export OPENAI_API_KEY="sk-SOME_RANDOM_STRING`.

Minion also assumes that you have [jq](https://jqlang.github.io/jq/) installed. If you have [Homebrew](https://brew.sh/) installed, it's as easy as `brew install jq` to get it.

## Features

### Generate commit message

Ease the generation of a [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) style commit message.

```bash
minion commit
```

Prompt:

```text
Generate a Conventional Commits style commit message for the following changes. Use a compact and terse style. For things like dependencies and other verbose changes, bundle these changes into an overall change description. These are the changes:
```

### Code review

Have ChatGPT generate a code review, focusing on issues and to give feedback on how the changes could be refactored.

```bash
minion review
```

Prompt:

```text
You are a world-class software engineer. You have been assigned to review the following changes. You will provide actionable feedback while having a supportive tone. Focus on issues and problems, not mincing words. Highlight the issues and address each separately. If one issue is very similar to another, group them together. If one issue has effect on another, explain how. Give feedback on things that could be refactored or improved with common design patterns. Also, ensure any new code has tests if applicable (i.e. not for dependencies, version changes, configuration, or similar). These are the changes:
```

### Write tests for changes

Generate tests for your changes. _Make sure to set the `TEST_TOOL` variable to a relevant choice for you._

```bash
minion test
```

Prompt:

```text
You are a world-class software engineer. You have been asked to write appropriate unit tests using $TEST_TOOL for the changes. Tests should only be made for our source code, not for dependencies, version changes, configuration, or similar. We are aiming for full code coverage, if possible. If there are no applicable changes, don't write any tests. These are the changes:
```

### Ask a question

Finally, you may just want to conveniently ask a question!

```bash
minion ask "Tell me about 5 practical ways to minimize technical debt in a React project."
```

## Installation

You can use it just as any old script in a project if you want...

_But the nicer option is to use the `install.sh` script._

It will:

- Make a root level directory named `.minion`
- Copy `minion.sh` to the new directory
- Add a line to your `.zshrc` with an alias (`minion`) that runs the script

Feel free to modify the installation script or do it your way if this doesn't match how you'd like it to be set up.

You will need to source or reload your IDE for the changes to be activated.

## Configuration

The model used is `gpt-3.5-turbo-16k`. If you want to change this, simply update the `MODEL` variable to the model you want to use.

For tests, the prompt is explicit about the tool to use. To change the tool to something other than [Jest](https://jestjs.io), update the value of `TEST_TOOL`.

## Usage

Run `minion [commit|review|test|ask]` in a Git repository.

## Contributing

There is a dedicated [CONTRIBUTING.md](CONTRIBUTING.md), but generally I'm happy to take suggestions and proposals for new features!
