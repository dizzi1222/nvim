1. Estos .lua no son basura. 

2. Puedes usar estas IA [pero la mayoria son de pagos, incluso code companion y copilot chat las que uso..]  >> Por eso GEMINI-cli >>> Claude.

3. Muchas de estas config son redudantes, ya que usan PACKER.nvim.

4. Si, Lazyvim no es lo mismo que nvim-packer.

----------------------------------------------------
	[REDUNDANTE] { Lazyvim las incluye}
----------------------------------------------------

~ Conform [mejor que none-ls formatter]
~ LSP-config
~ vim-tmux-navigator
~ treesitter
~ cmp
~ marks

----------------------------------------------------
	[IAS] { De Pago TODAS, por eso Gemini-cli goat}
----------------------------------------------------

---------
meh
---------
~ Supermaven [el MEJOR autocomplete >> copilot]
~ Tabnine [la unica gratis]
~ Copilot [gratis por unos minutos XD]
~ Codecompanion [Configurar IAS]
---------
MRD
---------

~ avante [PAGO]
~ claude-code [PAGO]
~ Opencode [PAGO - dogshit]
~ gemini.lua [PAGO] ~ no confundir con gemini-cli.

----------------------------------------------------
	[LORE] { +Recomendaciones}
----------------------------------------------------

~ treesitter.lua - Es la base de toda la navegacion y funciones de nvim [Lazyvim]
~ CMP - Lo mismo que treesitter [Lazyvim]
~ lsp-config - Lo mismo que treesitter [Lazyvim]
~ fzf.lua - Busqueda, redundante [peor que snacks]
~ telescope.lua - Lo mismo que fzf lua
~ marks.lua - Markdown para archivos .md, ya viene incluido [Lazyvim]
~ precognition - (solo útil aprendiendo Vim)
~ vim-be-good - Desafio para entender vim [similar a Vim Tutorial]
~ vim-tmux-navigator.lua - Navegar tab, En lazyvim basta vim-navigation
~ none-ls - Formatter, LazyVim usa conform por default
~ conform.lua - Formatter [Lazyvim]
~ Volt + minty.lua - Selector de color raro [de NVChad]
---------
ELIMINE si o si:
---------
~ Harpoon - Guardar marcadores, se desactiva en lazy.lua [editor] (prefieres Grapple) 
~ Editor - Para vistas previas de funciones [snacks ya hace esto?] 
		󱞩 [Mas ajutes de Gentleman xd] incluye:
		~ goto-preview - ventanas flotantes
		~ mini.hipatterns - Resaltar colores [uso mejor colorizer]
		~ git.nvim - Git blame (quién escribió cada línea [ya lo tengo integro]
		

----------------------------------------------------
	[GOD] { +what u need}
----------------------------------------------------

1~ grapple - redundante PERO mejor que Harpon [activable en lazy.lua] in my books:

Space + H + H > Abrir los marcadores
Space + H + F > Guar a los marcores

		󱞩 Util para acceder rapido!!

󰀦 Configurarlo requiere:

1. Instalar adaptadores específicos por lenguaje (ej: vscode-js-debug para JavaScript)
2. Configurar cada lenguaje en tu nvim-dap.lua		
		
---------------------------
2~ multi-line (útil para formateo rápido)

	󱞩 Util para objetos, arrays, parametros de funciones... TS, JS.
	
	~ Atajos típicos:
	
gS - Split (dividir en múltiples líneas)
gJ - Join (juntar en una línea)
	
---------------------------
3~ nvim-dap (si debuggeas, si no ELIMÍNALO)

Space + D + B > Para poner breakpoints

󱞩 ¿Lo necesitas? Solo si debuggeas código regularmente. Si usas console.log() para todo, no lo necesitas. Si trabajas con bugs complejos o backend, es muy útil.

		~ Atajos típicos:
		
      󱞩 <F5> - Iniciar/continuar debugging
	<F10> - Step over (siguiente línea)
	<F11> - Step into (entrar en función)
	<leader>db - Toggle breakpoint

---------------------------
4~ ~ numb.lua - detalle menor PERO VISTA PREVIA GOD

Solo basta con :50 [el numero] y vista previa de esa linea.

---------------------------
5~ inline-fold - Para colapsar imports muy largos

---------------------------
6~ screenkey - solo para screencasts 
	
	󱞩 Muestra la tecla que presionas en la status bar, util para tutoriales, muy lindo

---------------------------
7~ comment - Util para manejar comentarios

---------------------------
8~ indent_blankline - Identacion visual hermosa (visual útil)
 
	󱞩 Ej:
		function ejemplo() {
	│ if (condicion) {
	│ │ const valor = 10;
	│ │ if (otraCondicion) {
	│ │ │ console.log(valor);
	│ │ }
	│ }
	}
	
---------------------------
9 ~ Markdown - Render markdown para .md
			
		󱞩 Ej:
			① Mi Título
		② Subtítulo
		● Item 1
		● Item 2
		negrita cursiva (con estilos visuales)
