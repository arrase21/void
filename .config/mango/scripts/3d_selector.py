#!/usr/bin/env python3
import os
import sys
from PyQt6.QtWidgets import QApplication, QWidget, QLabel
from PyQt6.QtGui import QPixmap, QTransform, QKeyEvent
from PyQt6.QtCore import Qt, QSize

WALLPAPER_DIR = os.path.expanduser("~/wallpapers")

class WallpaperSelector3D(QWidget):
    def __init__(self):
        super().__init__()
        self.wallpapers = []
        self.current_index = 0
        
        # Estilo de la ventana principal
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.resize(1100, 500)
        
        # Cargar rutas de imágenes
        if os.path.exists(WALLPAPER_DIR):
            valid_exts = ('.jpg', '.jpeg', '.png', '.webp')
            self.wallpapers = [os.path.join(WALLPAPER_DIR, f) for f in sorted(os.listdir(WALLPAPER_DIR)) if f.lower().endswith(valid_exts)]
            
        if not self.wallpapers:
            print("Error: No se encontraron imágenes en ~/wallpapers", file=sys.stderr)
            sys.exit(1)
            
        self.current_index = len(self.wallpapers) // 2
        
        # Crear los contenedores de las tarjetas de imagen
        self.labels = []
        for _ in range(5):  # Mostraremos un máximo de 5 tarjetas simultáneas
            label = QLabel(self)
            label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            label.setScaledContents(True)
            label.setFixedSize(380, 240)
            self.labels.append(label)
            
        self.update_carousel()

    def update_carousel(self):
        # Limpiar todas las vistas previas
        for label in self.labels:
            label.hide()
            
        positions = [-2, -1, 0, 1, 2] # Distribución del carrusel alrededor del centro
        
        for pos in positions:
            idx = self.current_index + pos
            if 0 <= idx < len(self.wallpapers):
                label = self.labels[pos + 2]
                label.show()
                
                # Cargar imagen de forma optimizada
                pixmap = QPixmap(self.wallpapers[idx]).scaled(380, 240, Qt.AspectRatioMode.KeepAspectRatioByExpanding, Qt.TransformationMode.SmoothTransformation)
                label.setPixmap(pixmap)
                
                # --- AQUÍ OCURRE LA MAGIA DEL EFECTO 3D (Perspectiva y Rotación Y) ---
                transform = QTransform()
                
                # Centro de rotación del panel
                label.setTransformOriginPoint(190, 120)
                
                if pos < 0: # Lado izquierdo (inclinado hacia la derecha)
                    transform.translate(150 * pos, 0)
                    transform.rotate(35, Qt.Axis.YAxis)
                    label.raise_()
                elif pos > 0: # Lado derecho (inclinado hacia la izquierda)
                    transform.translate(150 * pos, 0)
                    transform.rotate(-35, Qt.Axis.YAxis)
                    label.raise_()
                else: # Centro (Al frente de todo)
                    transform.scale(1.15, 1.15)
                    
                label.setTransform(transform)
                
                # Centrar los elementos físicamente en la pantalla de la app
                center_x = (self.width() - label.width()) // 2
                center_y = (self.height() - label.height()) // 2
                label.move(center_x, center_y)
                
        # Asegurar que el elemento del centro quede arriba en orden Z
        self.labels[2].raise_()

    def keyPressEvent(self, event: QKeyEvent):
        if event.key() == Qt.Key.Key_Left and self.current_index > 0:
            self.current_index -= 1
            self.update_carousel()
        elif event.key() == Qt.Key.Key_Right and self.current_index < len(self.wallpapers) - 1:
            self.current_index += 1
            self.update_carousel()
        elif event.key() in [Qt.Key.Key_Return, Qt.Key.Key_Enter]:
            # Retorna el wallpaper seleccionado a la terminal
            print(self.wallpapers[self.current_index])
            sys.exit(0)
        elif event.key() == Qt.Key.Key_Escape:
            sys.exit(1)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    selector = WallpaperSelector3D()
    selector.show()
    sys.exit(app.exec())
