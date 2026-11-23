# uCrop (image_cropper) references OkHttp only to download remote images,
# which the app never does. OkHttp is not a dependency, so R8 must not fail.
-dontwarn okhttp3.**
-dontwarn okio.**
