import glob
import os
import re
import sys

from PIL import Image, ImageDraw


source_directory, output_path = sys.argv[1:3]
start_milliseconds = int(sys.argv[3]) if len(sys.argv) > 3 else 0
end_milliseconds = int(sys.argv[4]) if len(sys.argv) > 4 else 24_000
columns = int(sys.argv[5]) if len(sys.argv) > 5 else 6
files = glob.glob(os.path.join(source_directory, 'frame_*.png'))
timestamped_files = sorted([
    (path, int(re.search(r'_(\d{6})ms', path).group(1)))
    for path in files
], key=lambda item: item[1])
selected_files = [
    path
    for path, timestamp in timestamped_files
    if start_milliseconds <= timestamp <= end_milliseconds
]

thumb_width = 180
thumb_height = 327
label_height = 24
rows = (len(selected_files) + columns - 1) // columns
sheet = Image.new(
    'RGB',
    (thumb_width * columns, (thumb_height + label_height) * rows),
    (20, 20, 22),
)
draw = ImageDraw.Draw(sheet)
for index, path in enumerate(selected_files):
    frame = Image.open(path).convert('RGB')
    frame.thumbnail((thumb_width, thumb_height))
    x = (index % columns) * thumb_width
    y = (index // columns) * (thumb_height + label_height)
    sheet.paste(frame, (x, y))
    timestamp = re.search(r'_(\d{6})ms', path).group(1)
    draw.text((x + 4, y + thumb_height + 4), f'{timestamp} ms', fill='white')

sheet.save(output_path, quality=92)
