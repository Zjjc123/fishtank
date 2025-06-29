import os
import shutil
import json
import sys

def create_imageset(image_path, output_dir):
    base = os.path.splitext(os.path.basename(image_path))[0]
    imageset_name = base[0].upper() + base[1:] + ".imageset"
    imageset_dir = os.path.join(output_dir, imageset_name)
    os.makedirs(imageset_dir, exist_ok=True)

    dest_image_path = os.path.join(imageset_dir, os.path.basename(image_path))
    shutil.copy(image_path, dest_image_path)

    contents = {
        "images": [
            {
                "idiom": "universal",
                "filename": os.path.basename(image_path),
                "scale": "1x"
            }
        ],
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }

    with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)

    print(f"Created {imageset_dir}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python create_imageset_batch.py /path/to/folder")
        sys.exit(1)

    input_dir = sys.argv[1]
    for filename in os.listdir(input_dir):
        if filename.lower().endswith(".png"):
            image_path = os.path.join(input_dir, filename)
            create_imageset(image_path, input_dir)
            