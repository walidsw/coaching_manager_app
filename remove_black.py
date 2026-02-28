from PIL import Image
import glob

for path in glob.glob("assets/images/cards/*.png"):
    img = Image.open(path).convert("RGBA")
    data = img.getdata()
    new_data = []
    for r, g, b, a in data:
        # Use max(r,g,b) as alpha to capture glow accurately
        alpha = max(r, g, b)
        if alpha == 0:
            new_data.append((0, 0, 0, 0))
        else:
            # Un-multiply the RGB so the color stays vibrant when overlayed
            new_r = int(min(255, r * 255 / alpha))
            new_g = int(min(255, g * 255 / alpha))
            new_b = int(min(255, b * 255 / alpha))
            new_data.append((new_r, new_g, new_b, alpha))
            
    img.putdata(new_data)
    img.save(path, "PNG")

print("Done converting black glow images to transparent!")
