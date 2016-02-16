heroku-pipeline-deploy
--------------------------------

This step allows you to promote a wercker deploy within a heroku pipeline. It is designed to work with a [heroku deploy step](https://app.wercker.com/#applications/51c829e73179be4478002157/tab/details) and not as a standalone deployment step.

## Options
There are 4 options (3 required) that can be passed in your `wercker.yml`:

- `user` This is the username that will be used to interact with the heroku toolbelt.
- `key` This is the API key that corresponds to the `user` property.
- `from` The name of the heroku app that you will be promoting.
- `to` _(optional)_ The destination app you will be promoting to. This can be omitted if you want to promote to the default promotion targets.

## Example Usage
As mentioned before, this step is **not** a standalone step. It should be used in addition to a [heroku deploy step](https://app.wercker.com/#applications/51c829e73179be4478002157/tab/details) for best experience. In the following example a deploy is triggered to a reference (your dev environment) and then it is promoted to the next environment (likely a beta or other pre-prod reference).

```yaml
deploy:
  steps:
    - heroku-deploy:
        key: API_KEY
        user: API_USERNAME
        app-name: SOURCE_APP_NAME
    - heroku-pipeline-deploy:
        key: API_KEY
        user: API_USERNAME
        from: SOURCE_APP_NAME
```
You can chain multiple `heroku-pipeline-deploy` steps together to promote as many times as you'd like

### Sources
- https://github.com/wercker/step-heroku-deploy (Heroku Deploy Step)
- https://devcenter.heroku.com/articles/pipelines (Heroku Pipeline Documentation)
