%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% mapc-proyecto.cls
%% Clase LaTeX para documentar proyectos propios de Miguel Ángel Peralta Cano
%% (GitHub: AnyelokDev). Pensada para el informe PDF que acompaña a un repo.
%%
%% El documento se lee en tres capas, y cada una debe poder leerse sola:
%%   Capa 1 (resumen)  : portada con ficha del proyecto, resumen, qué demuestra
%%                       y resultados clave.
%%   Capa 2 (técnica)  : contexto, arquitectura, implementación, decisiones de
%%                       diseño, problemas encontrados, seguridad, limitaciones.
%%   Capa 3 (anexos)   : evidencia, matriz de trazabilidad, glosario, referencias.
%%
%% Compilar:  pdflatex -> biber -> makeglossaries -> pdflatex x2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{mapc-proyecto}[2026/09/23 v1.0 Informe de proyecto personal MAPC]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[11pt,a4paper]{article}

%% ----------------------------------------------------------------- Base ----
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage[spanish,es-tabla,es-noquoting]{babel}
\RequirePackage{csquotes}
\RequirePackage{geometry}
\RequirePackage[table]{xcolor}
\RequirePackage{graphicx}
\RequirePackage{amsmath}
\RequirePackage{microtype}
\RequirePackage{etoolbox}
\RequirePackage{needspace}
\RequirePackage{lastpage}
\RequirePackage{array}
\RequirePackage{tabularx}
\RequirePackage{booktabs}
\RequirePackage{multirow}
\RequirePackage{makecell}
\RequirePackage{caption}
\RequirePackage{float}

%% --------------------------------------------------------------- Colores --
%% Regla de uso: el violeta es un acento. Sobre fondo blanco NUNCA va como
%% texto (contraste 2,7:1); como texto solo sobre negro (6,9:1).
%% Para texto sobre blanco se usa el morado (9:1).
\definecolor{mapcnegro}{HTML}{14111A}      % base: portada, cabeceras de tabla
\definecolor{mapcmorado}{HTML}{5B21B6}     % títulos, enlaces, destacados
\definecolor{mapcvioleta}{HTML}{A78BFA}    % acento: franjas, reglas, sobre negro
\definecolor{mapclila}{HTML}{F3EEFF}       % fondo de cajas
\definecolor{mapcgris}{HTML}{55525E}       % texto secundario
\definecolor{mapcgrisclaro}{HTML}{F4F3F7}  % fondos neutros
\definecolor{mapclinea}{HTML}{DDD8E6}      % líneas finas
% Semánticos: solo para estado y severidad
\definecolor{mapcrojo}{HTML}{B42318}
\definecolor{mapcambar}{HTML}{B54708}
\definecolor{mapcverde}{HTML}{067647}

%% ----------------------------------------------------------- Tipografía --
\RequirePackage{XCharter}
\RequirePackage[scaled=0.94]{FiraSans}
\RequirePackage[scaled=0.88]{FiraMono}
\RequirePackage[charter,cal=cmcal]{mathdesign}
\renewcommand{\familydefault}{\rmdefault}

%% ------------------------------------------------------------ Geometría --
\geometry{a4paper,top=2.7cm,bottom=2.7cm,left=2.5cm,right=2.5cm,
  headheight=15pt,headsep=14pt,footskip=1.3cm}
\setlength{\parskip}{0.4em}
\setlength{\parindent}{0pt}
\linespread{1.07}
\tolerance=2000
\emergencystretch=3em
\clubpenalty=10000
\widowpenalty=10000

%% ------------------------------------------------------------- Metadatos --
\newcommand{\proyecto}[1]{\def\mapc@proyecto{#1}}             \proyecto{}
\newcommand{\subtitulo}[1]{\def\mapc@subtitulo{#1}}           \subtitulo{}
\newcommand{\tipoproyecto}[1]{\def\mapc@tipo{#1}}             \tipoproyecto{Proyecto personal}
\newcommand{\autorproyecto}[1]{\def\mapc@autor{#1}}           \autorproyecto{Miguel Ángel Peralta Cano}
\newcommand{\usuariogithub}[1]{\def\mapc@github{#1}}          \usuariogithub{AnyelokDev}
\newcommand{\repositorio}[1]{\def\mapc@repo{#1}}              \repositorio{}
\newcommand{\stack}[1]{\def\mapc@stack{#1}}                   \stack{}
\newcommand{\contexto}[1]{\def\mapc@contexto{#1}}             \contexto{}
\newcommand{\estadoproyecto}[1]{\def\mapc@estado{#1}}         \estadoproyecto{Terminado}
\newcommand{\versiondoc}[1]{\def\mapc@version{#1}}            \versiondoc{1.0}
\newcommand{\fechadoc}[1]{\def\mapc@fecha{#1}}                \fechadoc{\today}
\newcommand{\clasificacion}[1]{\def\mapc@clasif{#1}}          \clasificacion{Público · portafolio}
\newcommand{\cabecera}[1]{\def\mapc@cabecera{#1}}             \cabecera{}

%% ---------------------------------------------------------------- Enlaces --
\RequirePackage{hyperref}
\hypersetup{colorlinks=true,linkcolor=mapcmorado,citecolor=mapcmorado,
  urlcolor=mapcmorado,filecolor=mapcmorado,breaklinks=true,pdfborder={0 0 0}}
\RequirePackage{xurl}
\urlstyle{same}
\RequirePackage[nameinlink,spanish]{cleveref}
\crefname{table}{tabla}{tablas}\Crefname{table}{Tabla}{Tablas}
\crefname{figure}{figura}{figuras}\Crefname{figure}{Figura}{Figuras}
\crefname{section}{sección}{secciones}\Crefname{section}{Sección}{Secciones}
\AtBeginDocument{\hypersetup{pdftitle={\mapc@proyecto},pdfauthor={\mapc@autor}}}

%% ---------------------------------------------------------------- Títulos --
%% Número de sección en morado, título en negro, regla violeta debajo.
\RequirePackage{titlesec}
\titleformat{\section}[hang]
  {\sffamily\Large\bfseries\color{mapcnegro}}
  {\textcolor{mapcmorado}{\thesection}}{0.8em}{}
  [{\vspace{3pt}\color{mapcvioleta}\titlerule[1.6pt]}]
\titleformat{\subsection}[hang]
  {\sffamily\large\bfseries\color{mapcmorado}}
  {\thesubsection}{0.6em}{}
\titleformat{\subsubsection}[hang]
  {\sffamily\normalsize\bfseries\color{mapcnegro}}
  {\thesubsubsection}{0.6em}{}
\titlespacing*{\section}{0pt}{1.7em}{0.8em}
\titlespacing*{\subsection}{0pt}{1.2em}{0.4em}
\titlespacing*{\subsubsection}{0pt}{0.9em}{0.3em}
% Evita títulos huérfanos al pie de página
\pretocmd{\section}{\Needspace{9\baselineskip}}{}{}
\pretocmd{\subsection}{\Needspace{6\baselineskip}}{}{}

\RequirePackage{tocloft}
\renewcommand{\cfttoctitlefont}{\sffamily\Large\bfseries\color{mapcnegro}}
\renewcommand{\cftsecfont}{\sffamily\bfseries\color{mapcnegro}}
\renewcommand{\cftsubsecfont}{\sffamily\small}
\renewcommand{\cftsecpagefont}{\sffamily\bfseries\color{mapcmorado}}
\renewcommand{\cftsubsecpagefont}{\sffamily\small}
\renewcommand{\cftsecleader}{\cftdotfill{\cftdotsep}}
\setlength{\cftbeforesecskip}{5pt}

%% ------------------------------------------------------- Cabecera y pie --
\RequirePackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\sffamily\footnotesize\color{mapcgris}\mapc@cabecera}
\fancyhead[R]{\sffamily\footnotesize\color{mapcgris}\mapc@autor\ \textbullet\ v\mapc@version}
\fancyfoot[L]{\sffamily\footnotesize\color{mapcgris}\mapc@clasif}
\fancyfoot[R]{\sffamily\footnotesize\color{mapcgris}\thepage\ de \pageref*{LastPage}}
\renewcommand{\headrule}{\color{mapcnegro}\hrule height 0.6pt}
\renewcommand{\footrule}{\color{mapcvioleta}\hrule height 1.4pt}
\renewcommand{\headrulewidth}{0.6pt}
\renewcommand{\footrulewidth}{1.4pt}
\let\ps@plain\ps@fancy

%% ---------------------------------------------------------------- Tablas --
\captionsetup{font={sf,small},labelfont={sf,bf,color=mapcmorado},
  labelsep=period,width=0.94\textwidth}
\renewcommand{\arraystretch}{1.3}
\setlength{\tabcolsep}{7pt}
\setlength{\heavyrulewidth}{1pt}
\setlength{\lightrulewidth}{0.4pt}
\arrayrulecolor{mapcnegro}
\newcolumntype{L}[1]{>{\raggedright\arraybackslash}p{#1}}
\newcolumntype{C}[1]{>{\centering\arraybackslash}p{#1}}
\newcolumntype{Y}{>{\raggedright\arraybackslash}X}
\newcolumntype{Z}{>{\centering\arraybackslash}X}
% Fila de encabezado: fondo negro y texto blanco
\newcommand{\filacab}{\rowcolor{mapcnegro}}
\newcommand{\thc}[1]{\textcolor{white}{\sffamily\bfseries\small #1}}
% Estado y severidad
\newcommand{\marca}[2]{\textcolor{#1}{\sffamily\bfseries\small #2}}
\newcommand{\sevalta}{\marca{mapcrojo}{ALTA}}
\newcommand{\sevmedia}{\marca{mapcambar}{MEDIA}}
\newcommand{\sevbaja}{\marca{mapcverde}{BAJA}}
\newcommand{\hecho}{\marca{mapcverde}{HECHO}}
\newcommand{\pendiente}{\marca{mapcambar}{PENDIENTE}}
\newcommand{\nocubierto}{\marca{mapcrojo}{NO CUBIERTO}}

%% ------------------------------------------------------------- Etiquetas --
%% \chip{T1136} : etiqueta corta en línea (técnicas, IDs de regla, versiones)
\RequirePackage[most]{tcolorbox}
\tcbuselibrary{skins,breakable}
\newtcbox{\chip}{on line,enhanced,colback=mapclila,colframe=mapclila,
  boxrule=0pt,arc=2pt,left=2.5pt,right=2.5pt,top=0.6pt,bottom=0.6pt,
  fontupper=\sffamily\small\bfseries\color{mapcmorado}}

%% ----------------------------------------------------------------- Cajas --
%% Todas comparten la misma base: barra lateral de color y título pequeño.
\tcbset{
  mapcbase/.style={enhanced,breakable,boxrule=0pt,arc=1.5pt,
    left=11pt,right=11pt,top=7pt,bottom=7pt,
    fonttitle=\sffamily\bfseries\small,coltitle=white,
    attach boxed title to top left={xshift=9pt,yshift=-2pt},
    boxed title style={boxrule=0pt,arc=1pt,left=5pt,right=5pt,top=1.5pt,bottom=1.5pt},
    before skip=11pt,after skip=11pt}
}
% Decisión de diseño: por qué el proyecto quedó así (la caja más importante)
\newtcolorbox{decision}[1][Decisión de diseño]{mapcbase,
  colback=mapclila,colframe=mapcmorado,colbacktitle=mapcmorado,
  borderline west={3pt}{0pt}{mapcmorado},title={#1}}
% Problema encontrado: síntoma, hipótesis, verificación y resultado
\newtcolorbox{problema}[1][Problema]{mapcbase,
  colback=mapcgrisclaro,colframe=mapcnegro,colbacktitle=mapcnegro,
  borderline west={3pt}{0pt}{mapcvioleta},title={#1}}
% Hallazgo o resultado clave (capa 1)
\newtcolorbox{hallazgo}[1][Resultado]{mapcbase,breakable=false,
  colback=white,colframe=mapcnegro,colbacktitle=mapcnegro,
  borderline west={3pt}{0pt}{mapcvioleta},title={#1}}
% Nota: aclaración breve que el lector necesita para seguir
\newtcolorbox{nota}[1][Nota]{mapcbase,
  colback=mapcgrisclaro,colframe=mapcgris,colbacktitle=mapcgris,
  borderline west={3pt}{0pt}{mapcgris},title={#1}}
% Riesgo o advertencia
\newtcolorbox{riesgo}[1][Riesgo]{mapcbase,breakable=false,
  colback=mapcrojo!5,colframe=mapcrojo,colbacktitle=mapcrojo,
  borderline west={3pt}{0pt}{mapcrojo},title={#1}}
% Limitación conocida: lo que el proyecto no hace o no probó
\newtcolorbox{limitacion}[1][Limitación]{mapcbase,breakable=false,
  colback=mapcambar!6,colframe=mapcambar,colbacktitle=mapcambar,
  borderline west={3pt}{0pt}{mapcambar},title={#1}}
% Recomendación o siguiente paso
\newtcolorbox{recomendacion}[1][Siguiente paso]{mapcbase,breakable=false,
  colback=mapcverde!5,colframe=mapcverde,colbacktitle=mapcverde,
  borderline west={3pt}{0pt}{mapcverde},title={#1}}

% Campos rotulados para usar dentro de las cajas
\newcommand{\campo}[2]{\par\noindent{\sffamily\bfseries\small\color{mapcmorado}#1.}\ #2\par}
\newcommand{\sintoma}[1]{\campo{Síntoma}{#1}}
\newcommand{\hipotesis}[1]{\campo{Hipótesis}{#1}}
\newcommand{\verificacion}[1]{\campo{Verificación}{#1}}
\newcommand{\resultado}[1]{\campo{Resultado}{#1}}
\newcommand{\contextodecision}[1]{\campo{Contexto}{#1}}
\newcommand{\eleccion}[1]{\campo{Qué se eligió}{#1}}
\newcommand{\porque}[1]{\campo{Por qué}{#1}}
\newcommand{\descartado}[1]{\campo{Qué se descartó}{#1}}

%% ----------------------------------------------------- Código y terminal --
%% Estilo por defecto: archivos (claro). style=terminal: comandos (oscuro).
\RequirePackage{listings}
\lstdefinestyle{mapcbase}{
  basicstyle=\ttfamily\footnotesize,breaklines=true,columns=fullflexible,
  keepspaces=true,showstringspaces=false,xleftmargin=9pt,xrightmargin=9pt,
  framesep=7pt,aboveskip=9pt,belowskip=9pt,
  literate={á}{{\'a}}1 {é}{{\'e}}1 {í}{{\'i}}1 {ó}{{\'o}}1 {ú}{{\'u}}1
           {ñ}{{\~n}}1 {Á}{{\'A}}1 {É}{{\'E}}1 {Í}{{\'I}}1 {Ó}{{\'O}}1
           {Ú}{{\'U}}1 {Ñ}{{\~N}}1 {¿}{{?`}}1 {¡}{{!`}}1 {≥}{{$\geq$}}1
           {→}{{$\rightarrow$}}1}
\lstdefinestyle{archivo}{style=mapcbase,frame=leftline,rulecolor=\color{mapcvioleta},
  framerule=2pt,backgroundcolor=\color{mapcgrisclaro},
  basicstyle=\ttfamily\footnotesize\color{mapcnegro},
  commentstyle=\color{mapcgris}\itshape}
\lstdefinestyle{terminal}{style=mapcbase,frame=single,rulecolor=\color{mapcnegro},
  backgroundcolor=\color{mapcnegro},basicstyle=\ttfamily\footnotesize\color{white},
  commentstyle=\color{mapcvioleta},morecomment=[l]{\#}}
\lstset{style=archivo}
\BeforeBeginEnvironment{lstlisting}{\Needspace{4\baselineskip}}

%% ----------------------------------------------------------------- Listas --
\RequirePackage{enumitem}
\setlist{itemsep=2pt,parsep=1pt,topsep=4pt}
\setlist[itemize,1]{label=\textcolor{mapcmorado}{\rule[0.18em]{0.4em}{0.4em}},leftmargin=1.4em}
\setlist[itemize,2]{label=\textcolor{mapcgris}{\textendash},leftmargin=1.2em}
\setlist[enumerate,1]{label=\sffamily\bfseries\textcolor{mapcmorado}{\arabic*.},leftmargin=1.6em}

%% -------------------------------------------------------------- Evidencia --
%% \evidencia[ancho]{archivo}{pie de figura}{etiqueta}
%% Captura con marco fino, para que no se funda con la página.
\newcommand{\evidencia}[4][0.92\textwidth]{%
  \begin{figure}[!htb]\centering
  {\setlength{\fboxsep}{0pt}\setlength{\fboxrule}{0.6pt}%
   \color{mapclinea}\fbox{\includegraphics[width=#1]{#2}}}%
  \caption{#3}\label{#4}
  \end{figure}}

%% --------------------------------------------------------------- Diagramas --
\RequirePackage{tikz}
\usetikzlibrary{arrows.meta,positioning,calc,fit,backgrounds}
\tikzset{
  nodo/.style={rectangle,rounded corners=3pt,draw=mapcnegro,line width=0.8pt,
    fill=white,text=mapcnegro,font=\sffamily\small,align=center,
    minimum width=2.8cm,minimum height=1cm,inner sep=5pt},
  nodooscuro/.style={nodo,fill=mapcnegro,text=white,font=\sffamily\small\bfseries},
  nodoacento/.style={nodo,draw=mapcmorado,fill=mapclila,text=mapcmorado,font=\sffamily\small\bfseries},
  zona/.style={rectangle,rounded corners=4pt,draw=mapcvioleta,dashed,line width=0.8pt,inner sep=8pt},
  flecha/.style={-{Stealth[length=2.6mm,width=2mm]},line width=0.9pt,draw=mapcnegro},
  flechaacento/.style={flecha,draw=mapcmorado},
  etiq/.style={font=\sffamily\scriptsize,text=mapcgris,inner sep=2pt,fill=white}
}

%% ---------------------------------------------------------------- Portada --
%% Bloque negro superior con el título; ficha del proyecto y control
%% documental abajo. Sin logo: la identidad es el nombre y los colores.
\newcommand{\mapc@fila}[2]{\ifdefempty{#2}{}{%
  \leavevmode\textcolor{mapcmorado}{\sffamily\bfseries\small #1} &
  \leavevmode{\small #2} \\}}
\newcommand{\portada}{%
\begin{titlepage}
\thispagestyle{empty}
\begin{tikzpicture}[remember picture,overlay]
  \fill[mapcnegro] (current page.north west) rectangle
    ([yshift=-0.52\paperheight]current page.north east);
  \fill[mapcvioleta] ([yshift=-0.52\paperheight]current page.north west) rectangle
    ([yshift=-0.52\paperheight-5pt]current page.north east);
  \node[anchor=north west,text width=0.8\paperwidth,align=left]
    at ([xshift=2.5cm,yshift=-2.4cm]current page.north west)
    {{\sffamily\small\bfseries\color{mapcvioleta}\MakeUppercase{\mapc@tipo}}};
  \node[anchor=south west,text width=0.78\paperwidth,align=left,inner sep=0pt]
    at ([xshift=2.5cm,yshift=-0.52\paperheight+2.2cm]current page.north west)
    {{\sffamily\fontsize{28}{33}\selectfont\bfseries\color{white}\mapc@proyecto}\par
     \vspace{12pt}
     {\sffamily\large\color{white!82}\mapc@subtitulo}\par
     \vspace{18pt}
     {\sffamily\small\color{mapcvioleta}\mapc@autor\ \ \textbullet\ \ github.com/\mapc@github}};
\end{tikzpicture}
\vspace*{0.47\paperheight}

\noindent{\sffamily\footnotesize\bfseries\color{mapcnegro}FICHA DEL PROYECTO}\par
\vspace{4pt}
{\renewcommand{\arraystretch}{1.45}\setlength{\parskip}{0pt}%
\begin{tabularx}{\textwidth}{@{}L{3.1cm}Y@{}}
\toprule
\mapc@fila{Autor}{\mapc@autor}
\mapc@fila{Repositorio}{\mapc@repo}
\mapc@fila{Stack}{\mapc@stack}
\mapc@fila{Contexto}{\mapc@contexto}
\bottomrule
\end{tabularx}}

\vfill
\noindent{\sffamily\footnotesize\bfseries\color{mapcnegro}CONTROL DOCUMENTAL}\par
\vspace{4pt}
{\renewcommand{\arraystretch}{1.35}\setlength{\parskip}{0pt}\footnotesize%
\begin{tabularx}{\textwidth}{@{}L{2.5cm}Y L{2.5cm}Y@{}}
\toprule
\sffamily\bfseries Versión & \mapc@version & \sffamily\bfseries Fecha & \mapc@fecha \\
\sffamily\bfseries Estado & \mapc@estado & \sffamily\bfseries Clasificación & \mapc@clasif \\
\bottomrule
\end{tabularx}}
\end{titlepage}
\pagestyle{fancy}
}

%% --------------------------------------------------------------- Capa 1 --
\newcommand{\seccionsn}[1]{\section*{#1}\addcontentsline{toc}{section}{#1}}

% Resumen del proyecto: una página como máximo
\newenvironment{resumen}{%
  \seccionsn{Resumen}%
  \begin{tcolorbox}[enhanced,breakable,colback=mapclila,colframe=mapclila,
     boxrule=0pt,arc=2pt,left=14pt,right=14pt,top=12pt,bottom=12pt,
     borderline west={5pt}{0pt}{mapcmorado}]
  \setlength{\parskip}{0.7em}\setlength{\parindent}{0pt}%
}{\end{tcolorbox}}

%% ---------------------------------------------------------------- Anexos --
%% Usar \iniciaranexos (no \appendix): numera "Anexo A" y ensancha el índice.
%% Para citar un anexo use \ref{etiqueta}, no \cref (duplicaría "Anexo").
\newcommand{\iniciaranexos}{%
  \appendix
  \renewcommand{\thesection}{Anexo \Alph{section}}%
  \titleformat{\section}[hang]
    {\sffamily\Large\bfseries\color{mapcnegro}}
    {\textcolor{mapcmorado}{\thesection.}}{0.7em}{}
    [{\vspace{3pt}\color{mapcvioleta}\titlerule[1.6pt]}]%
  \addtocontents{toc}{\protect\setlength{\protect\cftsecnumwidth}{5.4em}}%
}

%% --------------------------------------------------------------- Glosario --
\RequirePackage[acronym,nomain,nonumberlist,nopostdot,toc]{glossaries}
\renewcommand{\glsnamefont}[1]{\sffamily\bfseries\textcolor{mapcmorado}{#1}}
\setacronymstyle{long-short}
\glsdisablehyper   % las siglas no se pintan como enlace
\makeglossaries

%% ------------------------------------------------------ Referencias APA 7 --
\RequirePackage[style=apa,backend=biber,sortlocale=es_ES,language=auto]{biblatex}
\DeclareLanguageMapping{spanish}{spanish-apa}

\endinput
