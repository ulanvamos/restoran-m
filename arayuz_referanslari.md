# Arayüz Referansları

Aşağıdaki kod parçacığı uygulamanın Splash / Karşılama ekranı için Stitch ile oluşturulmuş Tailwind CSS tabanlı prototiptir. Bu prototipten yola çıkarak Flutter UI kodlarını oluşturacağız.

```html
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>RESTORANIM - Luxury Dining</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;700;800&amp;family=Inter:wght@400;500;600&amp;family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
      tailwind.config = {
        darkMode: "class",
        theme: {
          extend: {
            colors: {
              "surface-variant": "#e4e2dd",
              "outline": "#75777e",
              "secondary": "#505f7c",
              "tertiary-fixed": "#dbe3f2",
              "on-tertiary-container": "#8a92a0",
              "on-surface-variant": "#45464d",
              "on-surface": "#1b1c19",
              "inverse-on-surface": "#f2f1ec",
              "secondary-container": "#cbdafd",
              "on-primary-fixed-variant": "#3b4662",
              "primary-fixed": "#d9e2ff",
              "on-secondary-fixed-variant": "#384763",
              "error-container": "#ffdad6",
              "surface-container": "#f0eee9",
              "surface-tint": "#525e7b",
              "on-background": "#1b1c19",
              "on-tertiary-fixed": "#141c27",
              "on-primary-fixed": "#0e1b34",
              "on-primary": "#ffffff",
              "on-tertiary": "#ffffff",
              "surface-container-highest": "#e4e2dd",
              "surface-dim": "#dbdad5",
              "on-secondary-fixed": "#0b1b35",
              "primary": "#1E2A44",
              "secondary-fixed-dim": "#b7c7e9",
              "outline-variant": "#c5c6ce",
              "tertiary": "#0e1721",
              "primary-fixed-dim": "#bac6e7",
              "tertiary-fixed-dim": "#bfc7d6",
              "on-secondary-container": "#505f7d",
              "on-primary-container": "#8591b0",
              "surface-container-lowest": "#ffffff",
              "inverse-primary": "#bac6e7",
              "tertiary-container": "#232b36",
              "surface-container-high": "#eae8e3",
              "inverse-surface": "#30312e",
              "secondary-fixed": "#d7e2ff",
              "on-error-container": "#93000a",
              "background": "#F7F5F0",
              "on-tertiary-fixed-variant": "#3f4753",
              "on-secondary": "#ffffff",
              "surface-container-low": "#f5f3ee",
              "error": "#ba1a1a",
              "on-error": "#ffffff",
              "surface": "#F7F5F0",
              "primary-container": "#1E2A44",
              "surface-bright": "#F7F5F0"
            },
            fontFamily: {
              "headline": ["Manrope"],
              "body": ["Inter"],
              "label": ["Inter"]
            },
            borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
          },
        },
      }
    </script>
<style>
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 200, 'GRAD' 0, 'opsz' 24;
        }
        body {
            min-height: max(884px, 100dvh);
            background-color: #F7F5F0;
        }
    </style>
</head>
<body class="bg-[#F7F5F0] font-body text-[#1E2A44] antialiased h-screen overflow-hidden flex flex-col items-center justify-center">
<main class="flex flex-col items-center justify-center px-8 w-full max-w-sm">
<!-- Centerpiece Icon -->
<div class="w-32 h-32 rounded-full border border-[#1E2A44] border-[1px] flex items-center justify-center mb-12 bg-transparent">
<span class="material-symbols-outlined text-[#1E2A44] text-5xl" data-icon="restaurant">restaurant</span>
</div>
<!-- Brand Identity -->
<div class="text-center space-y-6 w-full">
<h1 class="font-headline font-extrabold text-2xl tracking-[0.4em] text-[#1E2A44] uppercase">
                RESTORANIM
            </h1>
<!-- Divider -->
<div class="w-12 h-[1px] bg-[#C9D1E0] mx-auto"></div>
<!-- Tagline -->
<p class="font-body text-[#6B7A99] text-sm tracking-[0.15em] font-medium italic">
                Yerinde ve zamanında lezzet
            </p>
</div>
</main>
<!-- No footer indicators for ultra-minimal look -->
</body>
</html>
```
