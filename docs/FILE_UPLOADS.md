# File Uploads / Image Attachments

Landgrab supports uploading images for attaching to posts, including a media library (below) for inserting images into a post's text. This feature uses [ActiveSupport](https://guides.rubyonrails.org/active_storage_overview.html) (bundled with Ruby on Rails) for managing file uploads.

Files are stored in a cloud storage service which means this needs configuring within landgrab before anything can be uploaded.

## Set up Cloudinary

We'll use [Cloudinary](https://cloudinary.com/) for hosting our files, although the implementation can generically support swapping this out for an alternative (such as [Cloudflare R2](https://www.cloudflare.com/en-gb/developer-platform/products/r2/) with a small amount of configuration required.

Note: We do not use Cloudinary's native image processing capabilities; we only use the service for storage. Image manipulation (for example, to create "thumbnail" variants of images) is done within landgrab.

You'll need an account on Cloudinary and will need to set the following environment variables;
- set `CLOUDINARY_URL` to the authentication url provided in your Cloudinary dashboard.
- set `ACTIVE_STORAGE_SERVICE_PROVIDER` to "Cloudinary" so the system knows which configuration to use.

## Add Image Processing Dependencies

In order to generate thumbnails, the server requires a few dependencies (details [here](https://guides.rubyonrails.org/active_storage_overview.html#requirements)).

In the docker setup, we install [libvips](https://github.com/libvips/libvips).

Dependencies are detected/integrated by the `image_processing` gem.

## Media library

Admins write post text in a Markdown editor ([Toast UI Editor](https://github.com/nhn/tui.editor), loaded from its CDN) that opens in Markdown mode; WYSIWYG mode is opt-in via the switch under the editor. Note that WYSIWYG mode drops raw HTML blocks, so use Markdown mode for text that contains them.

Beside the editor is the post's image library:

- Images upload immediately (`Admin::MediaImagesController`), before the post is saved, and stay unattached until the post is saved with their signed ids. `PurgeUnattachedBlobsJob` removes uploads that never got attached, or that were removed from a post, after two days.
- Each image's alt text lives in its blob's `custom_metadata` and defaults to a cleaned-up version of the file name. Editing it in the library saves it straight away.
- Dragging an image into the text, or using its Insert button, adds Markdown for the `web` variant (`![alt](url)`). Ticking "Link to full size" wraps that in a link to the original image.
- Removing an image whose URL is still in the text asks for confirmation first.

A record gets a library by calling `media_library` from `MediaLibrary` and rendering `admin/shared/media_library` in its form (see posts).
