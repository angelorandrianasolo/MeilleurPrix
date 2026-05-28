"""
Interface graphique Tkinter pour le projet 2D Packing
"""

import tkinter as tk
from tkinter import ttk, messagebox
import random

from packing_1d import first_fit, best_fit, worst_fit, brute_force_1d
from packing_1d import get_counterexample_ff, get_counterexample_bf, get_counterexample_wf
from packing_2d import Rectangle, nfdh, ffdh, best_fit_2d, brute_force_2d, calculate_utilization
from packing_3shapes import Circle, RectShape, IsoscelesTriangle
from packing_3shapes import heuristic_3shapes, brute_force_3shapes, calculate_utilization_3shapes


class PackingGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("2D Packing - Projet Algorithmique")
        self.root.geometry("1200x800")
        self.rectangles_2d = []
        self.shapes_3d = []
        self.setup_ui()

    def setup_ui(self):
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        self.tab_1d = ttk.Frame(self.notebook)
        self.notebook.add(self.tab_1d, text="1D Packing")
        self.setup_1d_tab()
        self.tab_2d = ttk.Frame(self.notebook)
        self.notebook.add(self.tab_2d, text="2D Packing (Rectangles)")
        self.setup_2d_tab()
        self.tab_3shapes = ttk.Frame(self.notebook)
        self.notebook.add(self.tab_3shapes, text="3 Formes")
        self.setup_3shapes_tab()

    def setup_1d_tab(self):
        frame = ttk.Frame(self.tab_1d)
        frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        control = ttk.LabelFrame(frame, text="Parametres 1D")
        control.pack(fill=tk.X, pady=5)
        ttk.Label(control, text="Capacite du bac :").grid(row=0, column=0, padx=5, pady=5)
        self.bin_capacity_var = tk.StringVar(value="10")
        ttk.Entry(control, textvariable=self.bin_capacity_var, width=10).grid(row=0, column=1, padx=5)
        ttk.Label(control, text="Objets (separes par virgules) :").grid(row=1, column=0, padx=5, pady=5)
        self.items_var = tk.StringVar(value="6, 6, 3, 3, 3, 3, 2, 2")
        ttk.Entry(control, textvariable=self.items_var, width=40).grid(row=1, column=1, padx=5)
        btn_frame = ttk.Frame(control)
        btn_frame.grid(row=2, column=0, columnspan=2, pady=10)
        ttk.Button(btn_frame, text="First-Fit", command=self.run_ff_1d).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Best-Fit", command=self.run_bf_1d).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Worst-Fit", command=self.run_wf_1d).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Brute Force", command=self.run_brute_1d).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Tous les algos", command=self.run_all_1d).pack(side=tk.LEFT, padx=5)
        ttk.Separator(control, orient=tk.HORIZONTAL).grid(row=3, column=0, columnspan=2, sticky="ew", pady=10)
        ttk.Label(control, text="Contre-exemples :").grid(row=4, column=0, padx=5)
        ex_frame = ttk.Frame(control)
        ex_frame.grid(row=4, column=1, pady=5)
        ttk.Button(ex_frame, text="FF", command=lambda: self.load_example_1d("ff")).pack(side=tk.LEFT, padx=2)
        ttk.Button(ex_frame, text="BF", command=lambda: self.load_example_1d("bf")).pack(side=tk.LEFT, padx=2)
        ttk.Button(ex_frame, text="WF", command=lambda: self.load_example_1d("wf")).pack(side=tk.LEFT, padx=2)
        result_frame = ttk.LabelFrame(frame, text="Resultats")
        result_frame.pack(fill=tk.BOTH, expand=True, pady=5)
        self.result_1d_text = tk.Text(result_frame, height=20, wrap=tk.WORD)
        self.result_1d_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        scrollbar = ttk.Scrollbar(self.result_1d_text, command=self.result_1d_text.yview)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.result_1d_text.config(yscrollcommand=scrollbar.set)

    def get_1d_input(self):
        try:
            capacity = int(self.bin_capacity_var.get())
            items_str = self.items_var.get()
            items = [int(x.strip()) for x in items_str.split(",")]
            return capacity, items
        except ValueError:
            messagebox.showerror("Erreur", "Veuillez entrer des nombres valides")
            return None, None

    def run_ff_1d(self):
        capacity, items = self.get_1d_input()
        if items is None: return
        bins = first_fit(items, capacity)
        self.display_1d_result("First-Fit", bins, capacity, items)

    def run_bf_1d(self):
        capacity, items = self.get_1d_input()
        if items is None: return
        bins = best_fit(items, capacity)
        self.display_1d_result("Best-Fit", bins, capacity, items)

    def run_wf_1d(self):
        capacity, items = self.get_1d_input()
        if items is None: return
        bins = worst_fit(items, capacity)
        self.display_1d_result("Worst-Fit", bins, capacity, items)

    def run_brute_1d(self):
        capacity, items = self.get_1d_input()
        if items is None: return
        if len(items) > 12:
            messagebox.showwarning("Attention", "Brute force lent avec plus de 12 objets")
        bins = brute_force_1d(items, capacity)
        self.display_1d_result("Brute Force (Optimal)", bins, capacity, items)

    def run_all_1d(self):
        capacity, items = self.get_1d_input()
        if items is None: return
        self.result_1d_text.delete(1.0, tk.END)
        self.result_1d_text.insert(tk.END, "=== Comparaison des algorithmes 1D ===\n")
        self.result_1d_text.insert(tk.END, "Objets : " + str(items) + "\n")
        self.result_1d_text.insert(tk.END, "Capacite : " + str(capacity) + "\n\n")
        for name, func in [("First-Fit", first_fit), ("Best-Fit", best_fit), ("Worst-Fit", worst_fit), ("Brute Force", brute_force_1d)]:
            bins = func(items, capacity)
            self.result_1d_text.insert(tk.END, name + " : " + str(len(bins)) + " bacs\n")
            for b in bins:
                self.result_1d_text.insert(tk.END, "  " + str(b) + "\n")
            self.result_1d_text.insert(tk.END, "\n")

    def display_1d_result(self, algo_name, bins, capacity, items):
        self.result_1d_text.delete(1.0, tk.END)
        self.result_1d_text.insert(tk.END, "=== " + algo_name + " ===\n")
        self.result_1d_text.insert(tk.END, "Objets : " + str(items) + "\n")
        self.result_1d_text.insert(tk.END, "Capacite : " + str(capacity) + "\n")
        self.result_1d_text.insert(tk.END, "Nombre de bacs : " + str(len(bins)) + "\n\n")
        for b in bins:
            used = capacity - b.remaining
            pct = (used / capacity) * 100
            self.result_1d_text.insert(tk.END, "Bac " + str(b.id) + " : " + str(b.items) + " | Utilise : " + str(used) + "/" + str(capacity) + " (" + str(round(pct,1)) + "%)\n")

    def load_example_1d(self, algo):
        if algo == "ff": ex = get_counterexample_ff()
        elif algo == "bf": ex = get_counterexample_bf()
        else: ex = get_counterexample_wf()
        self.bin_capacity_var.set(str(ex["capacity"]))
        self.items_var.set(", ".join(map(str, ex["items"])))
        self.result_1d_text.delete(1.0, tk.END)
        self.result_1d_text.insert(tk.END, "=== " + ex["name"] + " ===\n")
        self.result_1d_text.insert(tk.END, ex["description"] + "\n")
        self.result_1d_text.insert(tk.END, "Optimal : " + str(ex["optimal_bins"]) + " bacs\n")

    def setup_2d_tab(self):
        frame = ttk.Frame(self.tab_2d)
        frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        control = ttk.LabelFrame(frame, text="Parametres 2D")
        control.pack(fill=tk.X, pady=5)
        ttk.Label(control, text="Largeur :").grid(row=0, column=0, padx=5, pady=5)
        self.W_var = tk.StringVar(value="300")
        ttk.Entry(control, textvariable=self.W_var, width=8).grid(row=0, column=1, padx=5)
        ttk.Label(control, text="Hauteur :").grid(row=0, column=2, padx=5)
        self.H_var = tk.StringVar(value="300")
        ttk.Entry(control, textvariable=self.H_var, width=8).grid(row=0, column=3, padx=5)
        ttk.Label(control, text="Rectangles (l1xh1, l2xh2, ...) :").grid(row=1, column=0, columnspan=2, padx=5, pady=5)
        self.rects_var = tk.StringVar(value="60x40, 60x40, 50x30, 50x30, 40x40, 30x30")
        ttk.Entry(control, textvariable=self.rects_var, width=40).grid(row=1, column=2, columnspan=2, padx=5)
        self.allow_rot_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(control, text="Autoriser rotation pi/2", variable=self.allow_rot_var).grid(row=2, column=0, columnspan=2, pady=5)
        btn_frame = ttk.Frame(control)
        btn_frame.grid(row=3, column=0, columnspan=4, pady=10)
        ttk.Button(btn_frame, text="NFDH", command=self.run_nfdh).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="FFDH", command=self.run_ffdh).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Best-Fit 2D", command=self.run_bf2d).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Brute Force", command=self.run_brute_2d).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Tous les algos", command=self.run_all_2d).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Generer aleatoire", command=self.generate_random_2d).pack(side=tk.LEFT, padx=5)
        canvas_frame = ttk.LabelFrame(frame, text="Visualisation")
        canvas_frame.pack(fill=tk.BOTH, expand=True, pady=5)
        self.canvas_2d = tk.Canvas(canvas_frame, bg="white", width=600, height=400)
        self.canvas_2d.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.result_2d_text = tk.Text(frame, height=5, wrap=tk.WORD)
        self.result_2d_text.pack(fill=tk.X, pady=5)

    def parse_rectangles(self):
        try:
            rects_str = self.rects_var.get()
            rectangles = []
            for i, r in enumerate(rects_str.split(",")):
                w, h = map(int, r.strip().split("x"))
                rectangles.append(Rectangle(w, h, i+1))
            return rectangles
        except ValueError:
            messagebox.showerror("Erreur", "Format invalide. Utilisez : l1xh1, l2xh2, ...")
            return None

    def get_container_size(self):
        try:
            W = int(self.W_var.get())
            H = int(self.H_var.get())
            return W, H
        except ValueError:
            messagebox.showerror("Erreur", "Taille invalide")
            return None, None

    def draw_2d_result(self, placed, W, H, algo_name):
        self.canvas_2d.delete("all")
        canvas_w = 600
        canvas_h = 400
        scale = min(canvas_w / W, canvas_h / H) * 0.9
        offset_x = (canvas_w - W * scale) / 2
        offset_y = (canvas_h - H * scale) / 2
        self.canvas_2d.create_rectangle(offset_x, offset_y, offset_x + W * scale, offset_y + H * scale, outline="black", width=2)
        colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"]
        for i, p in enumerate(placed):
            color = colors[i % len(colors)]
            x1 = offset_x + p.x * scale
            y1 = offset_y + p.y * scale
            x2 = offset_x + (p.x + p.width) * scale
            y2 = offset_y + (p.y + p.height) * scale
            self.canvas_2d.create_rectangle(x1, y1, x2, y2, fill=color, outline="black", width=1)
            label = "R" + str(p.id)
            if hasattr(p, "rotated") and p.rotated:
                label += "*"
            self.canvas_2d.create_text((x1+x2)/2, (y1+y2)/2, text=label, font=("Arial", 8))
        util = calculate_utilization(placed, W, H)
        self.result_2d_text.delete(1.0, tk.END)
        self.result_2d_text.insert(tk.END, algo_name + " : " + str(len(placed)) + " rectangles | Utilisation : " + str(round(util*100,1)) + "% | Conteneur : " + str(W) + "x" + str(H))

    def run_nfdh(self):
        W, H = self.get_container_size()
        rects = self.parse_rectangles()
        if rects is None or W is None: return
        placed = nfdh(rects, W, H, self.allow_rot_var.get())
        self.draw_2d_result(placed, W, H, "NFDH")

    def run_ffdh(self):
        W, H = self.get_container_size()
        rects = self.parse_rectangles()
        if rects is None or W is None: return
        placed = ffdh(rects, W, H, self.allow_rot_var.get())
        self.draw_2d_result(placed, W, H, "FFDH")

    def run_bf2d(self):
        W, H = self.get_container_size()
        rects = self.parse_rectangles()
        if rects is None or W is None: return
        placed = best_fit_2d(rects, W, H, self.allow_rot_var.get())
        self.draw_2d_result(placed, W, H, "Best-Fit 2D")

    def run_brute_2d(self):
        W, H = self.get_container_size()
        rects = self.parse_rectangles()
        if rects is None or W is None: return
        if len(rects) > 8:
            messagebox.showwarning("Attention", "Brute force lent avec plus de 8 rectangles")
        placed = brute_force_2d(rects, W, H, self.allow_rot_var.get())
        self.draw_2d_result(placed, W, H, "Brute Force")

    def run_all_2d(self):
        W, H = self.get_container_size()
        rects = self.parse_rectangles()
        if rects is None or W is None: return
        self.canvas_2d.delete("all")
        canvas_w = 600
        canvas_h = 400
        scale = min(canvas_w / W, canvas_h / H) * 0.4
        algorithms = [("NFDH", nfdh), ("FFDH", ffdh), ("Best-Fit", best_fit_2d)]
        colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7"]
        for idx, (name, func) in enumerate(algorithms):
            placed = func(rects, W, H, self.allow_rot_var.get())
            util = calculate_utilization(placed, W, H)
            offset_x = 20 + idx * (W * scale + 30)
            offset_y = 30
            self.canvas_2d.create_text(offset_x + W*scale/2, 15, text=name + " (" + str(len(placed)) + " objs, " + str(round(util*100,1)) + "%)", font=("Arial", 10, "bold"))
            self.canvas_2d.create_rectangle(offset_x, offset_y, offset_x + W * scale, offset_y + H * scale, outline="black", width=2)
            for i, p in enumerate(placed):
                color = colors[i % len(colors)]
                x1 = offset_x + p.x * scale
                y1 = offset_y + p.y * scale
                x2 = offset_x + (p.x + p.width) * scale
                y2 = offset_y + (p.y + p.height) * scale
                self.canvas_2d.create_rectangle(x1, y1, x2, y2, fill=color, outline="black", width=1)
                label = "R" + str(p.id)
                if hasattr(p, "rotated") and p.rotated:
                    label += "*"
                self.canvas_2d.create_text((x1+x2)/2, (y1+y2)/2, text=label, font=("Arial", 7))

    def generate_random_2d(self):
        n = random.randint(5, 10)
        W = int(self.W_var.get())
        H = int(self.H_var.get())
        rects = []
        for i in range(n):
            w = random.randint(20, W // 3)
            h = random.randint(20, H // 3)
            rects.append(str(w) + "x" + str(h))
        self.rects_var.set(", ".join(rects))

    def setup_3shapes_tab(self):
        frame = ttk.Frame(self.tab_3shapes)
        frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        control = ttk.LabelFrame(frame, text="Parametres 3 Formes")
        control.pack(fill=tk.X, pady=5)
        ttk.Label(control, text="Largeur :").grid(row=0, column=0, padx=5, pady=5)
        self.W3_var = tk.StringVar(value="400")
        ttk.Entry(control, textvariable=self.W3_var, width=8).grid(row=0, column=1, padx=5)
        ttk.Label(control, text="Hauteur :").grid(row=0, column=2, padx=5)
        self.H3_var = tk.StringVar(value="400")
        ttk.Entry(control, textvariable=self.H3_var, width=8).grid(row=0, column=3, padx=5)
        self.allow_rot3_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(control, text="Autoriser rotations pi/2 et pi", variable=self.allow_rot3_var).grid(row=1, column=0, columnspan=2, pady=5)
        add_frame = ttk.LabelFrame(control, text="Ajouter une forme")
        add_frame.grid(row=2, column=0, columnspan=4, pady=10, sticky="ew")
        self.shape_type_var = tk.StringVar(value="rectangle")
        ttk.Radiobutton(add_frame, text="Rectangle", variable=self.shape_type_var, value="rectangle").grid(row=0, column=0, padx=5)
        ttk.Radiobutton(add_frame, text="Cercle", variable=self.shape_type_var, value="circle").grid(row=0, column=1, padx=5)
        ttk.Radiobutton(add_frame, text="Triangle", variable=self.shape_type_var, value="triangle").grid(row=0, column=2, padx=5)
        ttk.Label(add_frame, text="Param 1 :").grid(row=1, column=0, padx=5)
        self.param1_var = tk.StringVar(value="50")
        ttk.Entry(add_frame, textvariable=self.param1_var, width=8).grid(row=1, column=1, padx=5)
        ttk.Label(add_frame, text="Param 2 :").grid(row=1, column=2, padx=5)
        self.param2_var = tk.StringVar(value="40")
        ttk.Entry(add_frame, textvariable=self.param2_var, width=8).grid(row=1, column=3, padx=5)
        ttk.Button(add_frame, text="Ajouter", command=self.add_shape).grid(row=1, column=4, padx=10)
        ttk.Button(add_frame, text="Effacer tout", command=self.clear_shapes).grid(row=1, column=5, padx=10)
        list_frame = ttk.LabelFrame(control, text="Formes a placer")
        list_frame.grid(row=3, column=0, columnspan=4, pady=5, sticky="ew")
        self.shapes_listbox = tk.Listbox(list_frame, height=5)
        self.shapes_listbox.pack(fill=tk.X, padx=5, pady=5)
        btn_frame = ttk.Frame(control)
        btn_frame.grid(row=4, column=0, columnspan=4, pady=10)
        ttk.Button(btn_frame, text="Heuristique", command=self.run_heuristic_3shapes).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Brute Force", command=self.run_brute_3shapes).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Generer aleatoire", command=self.generate_random_3shapes).pack(side=tk.LEFT, padx=5)
        canvas_frame = ttk.LabelFrame(frame, text="Visualisation")
        canvas_frame.pack(fill=tk.BOTH, expand=True, pady=5)
        self.canvas_3shapes = tk.Canvas(canvas_frame, bg="white", width=600, height=400)
        self.canvas_3shapes.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.result_3shapes_text = tk.Text(frame, height=4, wrap=tk.WORD)
        self.result_3shapes_text.pack(fill=tk.X, pady=5)

    def add_shape(self):
        shape_type = self.shape_type_var.get()
        try:
            p1 = float(self.param1_var.get())
            p2 = float(self.param2_var.get()) if self.param2_var.get() else 0
        except ValueError:
            messagebox.showerror("Erreur", "Valeurs numeriques invalides")
            return
        shape_id = len(self.shapes_3d) + 1
        if shape_type == "rectangle":
            shape = RectShape(p1, p2, shape_id)
            desc = "Rectangle " + str(p1) + "x" + str(p2)
        elif shape_type == "circle":
            shape = Circle(p1, shape_id)
            desc = "Cercle r=" + str(p1)
        elif shape_type == "triangle":
            shape = IsoscelesTriangle(p1, p2, shape_id)
            desc = "Triangle base=" + str(p1) + ", h=" + str(p2)
        self.shapes_3d.append(shape)
        self.shapes_listbox.insert(tk.END, desc)

    def clear_shapes(self):
        self.shapes_3d = []
        self.shapes_listbox.delete(0, tk.END)

    def draw_3shapes_result(self, placed, W, H, algo_name):
        self.canvas_3shapes.delete("all")
        canvas_w = 600
        canvas_h = 400
        scale = min(canvas_w / W, canvas_h / H) * 0.9
        offset_x = (canvas_w - W * scale) / 2
        offset_y = (canvas_h - H * scale) / 2
        self.canvas_3shapes.create_rectangle(offset_x, offset_y, offset_x + W * scale, offset_y + H * scale, outline="black", width=2)
        colors = {"rectangle": "#4ECDC4", "circle": "#FF6B6B", "triangle": "#45B7D1"}
        for p in placed:
            color = colors.get(p.shape_type, "gray")
            if p.shape_type == "rectangle":
                x1 = offset_x + p.x * scale
                y1 = offset_y + p.y * scale
                x2 = offset_x + (p.x + p.width) * scale
                y2 = offset_y + (p.y + p.height) * scale
                self.canvas_3shapes.create_rectangle(x1, y1, x2, y2, fill=color, outline="black")
                self.canvas_3shapes.create_text((x1+x2)/2, (y1+y2)/2, text="R" + str(p.id), font=("Arial", 8))
            elif p.shape_type == "circle":
                cx = offset_x + p.x * scale
                cy = offset_y + p.y * scale
                r = p.radius * scale
                self.canvas_3shapes.create_oval(cx-r, cy-r, cx+r, cy+r, fill=color, outline="black")
                self.canvas_3shapes.create_text(cx, cy, text="C" + str(p.id), font=("Arial", 8))
            elif p.shape_type == "triangle":
                vertices = p.get_vertices()
                scaled_vertices = []
                for vx, vy in vertices:
                    scaled_vertices.append(offset_x + vx * scale)
                    scaled_vertices.append(offset_y + vy * scale)
                self.canvas_3shapes.create_polygon(scaled_vertices, fill=color, outline="black")
                cx = sum(v[0] for v in vertices) / 3
                cy = sum(v[1] for v in vertices) / 3
                self.canvas_3shapes.create_text(offset_x + cx * scale, offset_y + cy * scale, text="T" + str(p.id), font=("Arial", 8))
        util = calculate_utilization_3shapes(placed, W, H)
        self.result_3shapes_text.delete(1.0, tk.END)
        self.result_3shapes_text.insert(tk.END, algo_name + " : " + str(len(placed)) + "/" + str(len(self.shapes_3d)) + " formes | Utilisation : " + str(round(util*100,1)) + "%")

    def run_heuristic_3shapes(self):
        try:
            W = float(self.W3_var.get())
            H = float(self.H3_var.get())
        except ValueError:
            messagebox.showerror("Erreur", "Taille invalide")
            return
        if not self.shapes_3d:
            messagebox.showwarning("Attention", "Ajoutez des formes d abord")
            return
        placed = heuristic_3shapes(self.shapes_3d, W, H, self.allow_rot3_var.get())
        self.draw_3shapes_result(placed, W, H, "Heuristique")

    def run_brute_3shapes(self):
        try:
            W = float(self.W3_var.get())
            H = float(self.H3_var.get())
        except ValueError:
            messagebox.showerror("Erreur", "Taille invalide")
            return
        if not self.shapes_3d:
            messagebox.showwarning("Attention", "Ajoutez des formes d abord")
            return
        if len(self.shapes_3d) > 6:
            messagebox.showwarning("Attention", "Brute force lent avec plus de 6 formes")
        placed = brute_force_3shapes(self.shapes_3d, W, H, self.allow_rot3_var.get())
        self.draw_3shapes_result(placed, W, H, "Brute Force")

    def generate_random_3shapes(self):
        self.clear_shapes()
        W = float(self.W3_var.get())
        H = float(self.H3_var.get())
        n = random.randint(4, 8)
        for i in range(n):
            shape_type = random.choice(["rectangle", "circle", "triangle"])
            if shape_type == "rectangle":
                w = random.randint(30, int(W)//4)
                h = random.randint(30, int(H)//4)
                self.shapes_3d.append(RectShape(w, h, i+1))
                self.shapes_listbox.insert(tk.END, "Rectangle " + str(w) + "x" + str(h))
            elif shape_type == "circle":
                r = random.randint(15, int(min(W,H))//6)
                self.shapes_3d.append(Circle(r, i+1))
                self.shapes_listbox.insert(tk.END, "Cercle r=" + str(r))
            else:
                b = random.randint(30, int(W)//4)
                h = random.randint(30, int(H)//4)
                self.shapes_3d.append(IsoscelesTriangle(b, h, i+1))
                self.shapes_listbox.insert(tk.END, "Triangle base=" + str(b) + ", h=" + str(h))


def main():
    root = tk.Tk()
    app = PackingGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
