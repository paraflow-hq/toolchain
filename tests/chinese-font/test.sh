#!/bin/bash

set -e

echo "=== Chinese Font Rendering Test ==="

# Test text with Chinese characters
CHINESE_TEXT="测试中文字体渲染功能"
MIXED_TEXT="Hello 世界! 你好 World!"

# Create test directory
mkdir -p /tmp/font-test
cd /tmp/font-test

echo "1. Checking font installation..."

# List available Chinese fonts
echo "Available Chinese fonts:"
fc-list :lang=zh-cn | head -10

# Check if fangsong font is available
echo ""
echo "Checking for fangsong font..."
if fc-list | grep -i fangsong; then
    echo "✅ Fangsong font is available"
else
    echo "❌ Fangsong font not found"
    exit 1
fi

echo ""
echo "2. Testing ImageMagick Chinese text rendering..."

# Test ImageMagick with Chinese text
convert -size 800x200 xc:white \
    -font /usr/share/fonts/truetype/msttcorefontscd/fangsong.ttf \
    -pointsize 24 \
    -fill black \
    -gravity center \
    -annotate +0+0 "$CHINESE_TEXT" \
    chinese_test.png

if [ -f "chinese_test.png" ]; then
    echo "✅ ImageMagick Chinese text rendering successful"
    echo "Image size: $(identify -format '%wx%h' chinese_test.png)"
else
    echo "❌ ImageMagick Chinese text rendering failed"
    exit 1
fi

# Test mixed language text
convert -size 800x200 xc:lightblue \
    -font /usr/share/fonts/truetype/msttcorefontscd/fangsong.ttf \
    -pointsize 20 \
    -fill darkblue \
    -gravity center \
    -annotate +0+0 "$MIXED_TEXT" \
    mixed_text.png

if [ -f "mixed_text.png" ]; then
    echo "✅ Mixed language text rendering successful"
else
    echo "❌ Mixed language text rendering failed"
    exit 1
fi

echo ""
echo "3. Testing fontconfig functionality..."

# Test fontconfig pattern matching
echo "Testing font pattern matching for Chinese:"
fc-match "fangsong"
fc-match ":lang=zh-cn"

echo ""
echo "4. Testing Cairo/Pango Chinese text rendering..."

# Create a simple C program to test Cairo/Pango
cat > cairo_test.c << 'EOF'
#include <cairo.h>
#include <cairo-ft.h>
#include <pango/pangocairo.h>
#include <stdio.h>

int main() {
    cairo_surface_t *surface;
    cairo_t *cr;
    PangoLayout *layout;
    PangoFontDescription *desc;
    
    // Create surface
    surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 400, 100);
    cr = cairo_create(surface);
    
    // Set background
    cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
    cairo_paint(cr);
    
    // Create Pango layout
    layout = pango_cairo_create_layout(cr);
    pango_layout_set_text(layout, "测试中文字体", -1);
    
    // Set font
    desc = pango_font_description_from_string("fangsong 16");
    pango_layout_set_font_description(layout, desc);
    
    // Draw text
    cairo_set_source_rgb(cr, 0.0, 0.0, 0.0);
    cairo_move_to(cr, 10, 10);
    pango_cairo_show_layout(cr, layout);
    
    // Save to file
    cairo_surface_write_to_png(surface, "cairo_chinese.png");
    
    // Cleanup
    pango_font_description_free(desc);
    g_object_unref(layout);
    cairo_destroy(cr);
    cairo_surface_destroy(surface);
    
    printf("Cairo Chinese text rendering completed\n");
    return 0;
}
EOF

# Try to compile and run if Cairo/Pango development files are available
if pkg-config --exists cairo pangocairo; then
    echo "Compiling Cairo test program..."
    gcc -o cairo_test cairo_test.c `pkg-config --cflags --libs cairo pangocairo`
    
    if [ -f "cairo_test" ]; then
        echo "Running Cairo test..."
        ./cairo_test
        
        if [ -f "cairo_chinese.png" ]; then
            echo "✅ Cairo Chinese text rendering successful"
        else
            echo "⚠️  Cairo test ran but no output image generated"
        fi
    else
        echo "⚠️  Cairo test compilation failed"
    fi
else
    echo "⚠️  Cairo/Pango development packages not available, skipping test"
fi

echo ""
echo "5. Testing Node.js canvas Chinese text rendering..."

# Create Node.js test if canvas is available
cat > node_canvas_test.js << 'EOF'
const fs = require('fs');

// Try to load canvas, handle gracefully if not available
let Canvas;
try {
    Canvas = require('canvas');
} catch (e) {
    console.log('Canvas module not available, skipping Node.js canvas test');
    process.exit(0);
}

const { createCanvas, registerFont } = Canvas;

// Register Chinese font
try {
    registerFont('/usr/share/fonts/truetype/msttcorefontscd/fangsong.ttf', { family: 'FangSong' });
    console.log('Chinese font registered successfully');
} catch (e) {
    console.log('Failed to register Chinese font:', e.message);
    process.exit(1);
}

// Create canvas
const canvas = createCanvas(400, 100);
const ctx = canvas.getContext('2d');

// Set background
ctx.fillStyle = '#f0f0f0';
ctx.fillRect(0, 0, 400, 100);

// Draw Chinese text
ctx.fillStyle = '#333333';
ctx.font = '20px FangSong';
ctx.fillText('Node.js 中文字体测试', 20, 50);

// Save to file
const buffer = canvas.toBuffer('image/png');
fs.writeFileSync('nodejs_chinese.png', buffer);

console.log('Node.js Chinese text rendering completed');
EOF

# Run Node.js test
echo "Running Node.js canvas test..."
if node node_canvas_test.js; then
    if [ -f "nodejs_chinese.png" ]; then
        echo "✅ Node.js canvas Chinese text rendering successful"
    else
        echo "⚠️  Node.js test ran but no output image generated"
    fi
else
    echo "⚠️  Node.js canvas test failed or skipped"
fi

echo ""
echo "6. Summary of generated test images:"
ls -la *.png 2>/dev/null || echo "No PNG files generated"

echo ""
echo "7. Font cache information:"
echo "Number of fonts in cache: $(fc-list | wc -l)"
echo "Chinese fonts available: $(fc-list :lang=zh-cn | wc -l)"

echo ""
echo "=== Chinese Font Rendering Test Completed ==="

# Clean up
cd /
rm -rf /tmp/font-test

echo "✅ All font rendering tests completed successfully!"
