# File Uploads / Image Attachments

Landgrab supports uploading images for attaching to posts. This feature uses [ActiveSupport](https://guides.rubyonrails.org/active_storage_overview.html) (bundled with Ruby on Rails) for managing file uploads.

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
