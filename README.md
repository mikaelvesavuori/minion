# Minion: Minimalist CLI wrapper for OpenAI APIs 👾

## The easiest and most lightweight way for developers to use OpenAI APIs in a CLI.

Minion is a simple CLI wrapper that calls OpenAI APIs with prefabbed prompts and your Git diff data. It expedites proactive - rather than reactive - code reviews, commit messaging, test generation, and diagramming.

## What to know

This solution uses cURL to call OpenAI APIs. OpenAI will not train their models based on API calls, so this is a "safer" solution than, for example, using the web version of ChatGPT.

## Prerequisites

You will need an [OpenAI API key](https://help.openai.com/en/articles/4936850-where-do-i-find-my-secret-api-key) and have it exported in the environment as `OPENAI_API_KEY`, i.e. run `export OPENAI_API_KEY="sk-SOME_RANDOM_STRING`.

**Minion assumes you have Bash.**

Minion also assumes that you have [jq](https://jqlang.github.io/jq/) installed. If you have [Homebrew](https://brew.sh/) installed, it's as easy as `brew install jq` to get it.

Further, the _installation script_ assumes a shell with Zsh support, as it modifies the `.zshrc` file. Exactly how you do the installation and mapping the command `minion` to the Bash script is ultimately up to you.

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

Have the LLM generate a code review, focusing on issues and to give feedback on how the changes could be refactored.

```bash
minion review
```

Prompt:

```text
You are a world-class software engineer. You have been assigned to review the following changes. You will provide actionable feedback while having a supportive tone. Focus on issues and problems, not mincing words. Highlight the issues and address each separately. If one issue is very similar to another, group them together. If one issue has effect on another, explain how. Give feedback on things that could be refactored or improved with common design patterns. Also, ensure any new code has tests if applicable (i.e. not for dependencies, version changes, configuration, or similar). These are the changes:
```

### Write tests for changes

Generate tests for your changes and your tool of choice.

```bash
minion test # Defaults to Jest

minion test {tool_name}
minion test ava
```

Prompt:

```text
You are a world-class software engineer. You have been asked to write appropriate unit tests using $TOOL for the changes. Tests should only be made for our source code, not for dependencies, version changes, configuration, or similar. We are aiming for full code coverage, if possible. If there are no applicable changes, don't write any tests. These are the changes:
```

### Create a diagram for changes

Generate one of several types of diagrams for your changes.

The allowed types are: `mermaid` (default), `uml`, `sequence_diagram`, `class_diagram`, `flowchart`, and `graphviz`.

```bash
minion diagram # Defaults to Mermaid

minion diagram {diagram_type}
minion diagram sequence_diagram
```

Prompt:

```text
You are a world-class software architect. You have been asked to produce diagrams using $TOOL for the changes. Focus on our own code, and only add external dependencies if necessary. If it's unclear what the solution is, then don't make diagrams and voice your concern and reasons for stopping. These are the changes:
```

### Ask a question

Finally, you may just want to conveniently ask a question!

```bash
minion ask "Tell me about 5 practical ways to minimize technical debt in a React project."
```

## Installation

The easiest "one-off" way would be to use Minion just as any old script in a project if you want...

_But the nicer option is to use the `install.sh` script._

It will:

- Make a root level directory named `.minion`
- Copy `minion.sh` to the new directory
- Add a line to your `.zshrc` with an alias (`minion`) that runs the script

_Please refer to the [Prerequisites](#prerequisites) section above before installing._

Feel free to modify the installation script or do it your way if this doesn't match how you'd like it to be set up.

You will need to source or reload your IDE for the changes to be activated.

## Configuration

The model used is `gpt-3.5-turbo-16k`. If you want to change this, simply update the `MODEL` variable to the model you want to use.

## Usage

Run `minion [commit|review|test|ask|diagram]` in a Git repository.

## Contributing

There is a dedicated [CONTRIBUTING.md](CONTRIBUTING.md), but generally I'm happy to take suggestions and proposals for new features!
