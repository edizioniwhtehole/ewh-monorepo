# Hello World Plugin

Example plugin demonstrating the EWH CMS plugin system.

## Features

- ✅ Action hooks (post.after_create, post.after_publish)
- ✅ Filter hooks (post.content, site.settings)
- ✅ Plugin settings storage
- ✅ Plugin data storage
- ✅ Logger integration

## Hooks Registered

### Actions
- `post.after_create` - Logs when a new post is created
- `post.after_publish` - Logs when a post is published

### Filters
- `post.content` - Adds custom processing to post content
- `site.settings` - Enhances site settings with plugin data

## Installation

The plugin is automatically loaded from `plugins/hello-world/` directory.

## Testing

Create a new post to see the plugin in action:

```bash
curl -X POST http://localhost:5200/api/posts \
  -H "Content-Type: application/json" \
  -d '{
    "site_id": "your-site-id",
    "title": "Test Post",
    "slug": "test-post",
    "content": {"blocks": []},
    "author_id": "user-id",
    "created_by": "user-id"
  }'
```

Check the logs to see plugin output.
