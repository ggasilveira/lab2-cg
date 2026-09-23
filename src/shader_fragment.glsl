#version 330 core

// Atributos de fragmentos recebidos como entrada ("in") pelo Fragment Shader.
// Neste exemplo, este atributo foi gerado pelo rasterizador como a
// interpolação da posição global e a normal de cada vértice, definidas em
// "shader_vertex.glsl" e "main.cpp".
in vec4 position_world;
in vec4 normal;

// Matrizes computadas no código C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Identificador que define qual objeto está sendo desenhado no momento
#define SPHERE 0
#define BUNNY  1
#define PLANE  2
uniform int object_id;

// O valor de saída ("out") de um Fragment Shader é a cor final do fragmento.
out vec4 color;

uniform int surface_type;

vec3 baseColor;
float metallic;
float subsurface;
float specular;
float roughness;
float specularTint;
float anisotropic;
float sheen;
float sheenTint;
float clearcoat;
float clearcoatGloss;

void setSurfaceParams()
{
    if ( surface_type == 1 )
    {
        // Gold surface
        baseColor       = 1.3 * vec3(.82, .67, .16);
        metallic        = 1.0;
        subsurface      = 0.0;
        specular        = 1.0;
        roughness       = 0.6;
        specularTint    = 0.0;
        anisotropic     = 0.0;
        sheen           = 0.0;
        sheenTint       = 0.0;
        clearcoat       = 0.0;
        clearcoatGloss  = 1.0;
    }
    else if ( surface_type == 4 )
    {
        // Red velvet / cloth surface
        baseColor       = vec3(0.85, 0.05, 0.03) * 0.5;
        metallic        = 0.0;
        subsurface      = 0.0;
        specular        = 0.55;
        roughness       = 0.75;
        specularTint    = 0.0;
        anisotropic     = 0.0;
        sheen           = 8.0;
        sheenTint       = 0.0;
        clearcoat       = 0.0;
        clearcoatGloss  = 1.0;
    }
    else if ( surface_type == 6 )
    {
        // Subsurface wax / jade-like surface
        baseColor       = vec3(0.0000, 0.6118, 0.2314) * 0.9; // Brazil green #009C3B
        metallic        = 0.0;
        subsurface      = 0.75;
        specular        = 0.45;
        roughness       = 0.55;
        specularTint    = 0.15;
        anisotropic     = 0.0;
        sheen           = 0.0;
        sheenTint       = 0.0;
        clearcoat       = 0.15;
        clearcoatGloss  = 0.65;
    }
    else if ( surface_type == 8 )
    {
        // Subsurface wax / jade-like surface
        baseColor       = vec3(0.226, 0.089, 0.0) * 0.9; // Brown
        metallic        = 0.0;
        subsurface      = 0.0;
        specular        = 0.55;
        roughness       = 0.75;
        specularTint    = 0.0;
        anisotropic     = 0.0;
        sheen           = 8.0;
        sheenTint       = 0.0;
        clearcoat       = 0.0;
        clearcoatGloss  = 1.0;
    }
    else
    {
        // Rough blue plastic surface
        baseColor       = vec3(0.0000, 0.1529, 0.4627) * 1.3; // Brazil blue #002776
        metallic        = 0.0;
        subsurface      = 0.0;
        specular        = 0.55;
        roughness       = 0.75;
        specularTint    = 0.0;
        anisotropic     = 0.0;
        sheen           = 0.0;
        sheenTint       = 0.0;
        clearcoat       = 0.0;
        clearcoatGloss  = 1.0;
    }
}

// Luzes direcionais configuradas diretamente no shader.
const int LIGHT_COUNT = 5;
const vec3 LIGHT_DIRECTIONS[LIGHT_COUNT] = vec3[](
    vec3(+10.0, 5.5, +10.0),
    vec3(+10.0, 5.5, -10.0),
    vec3(-10.0, 5.5, +10.0),
    vec3(-10.0, 5.5, -10.0),
    vec3(0.0, -1.0, 0.0)
);
const vec3 LIGHT_COLORS[LIGHT_COUNT] = vec3[](
    vec3(1.0, 1.0, 1.0),
    vec3(0.5, 0.5, 0.5),
    vec3(0.5, 0.5, 0.5),
    vec3(0.5, 0.5, 0.5),
    vec3(0.0, 0.2, 0.0)
);

// <START OF THIRD-PARTY SOURCE CODE>
// Copyright Disney Enterprises, Inc.  All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License
// and the following modification to it: Section 6 Trademarks.
// deleted and replaced with:
//
// 6. Trademarks. This License does not grant permission to use the
// trade names, trademarks, service marks, or product names of the
// Licensor and its affiliates, except as required for reproducing
// the content of the NOTICE file.
//
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

const float PI = 3.14159265358979323846;

float sqr(float x) { return x*x; }

float SchlickFresnel(float u)
{
    float m = clamp(1-u, 0, 1);
    float m2 = m*m;
    return m2*m2*m; // pow(m,5)
}

float GTR1(float NdotH, float a)
{
    if (a >= 1) return 1/PI;
    float a2 = a*a;
    float t = 1 + (a2-1)*NdotH*NdotH;
    return (a2-1) / (PI*log(a2)*t);
}

float GTR2(float NdotH, float a)
{
    float a2 = a*a;
    float t = 1 + (a2-1)*NdotH*NdotH;
    return a2 / (PI * t*t);
}

float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
{
    return 1 / (PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
}

float smithG_GGX(float NdotV, float alphaG)
{
    float a = alphaG*alphaG;
    float b = NdotV*NdotV;
    return 1 / (NdotV + sqrt(a + b - a*b));
}

float smithG_GGX_aniso(float NdotV, float VdotX, float VdotY, float ax, float ay)
{
    return 1 / (NdotV + sqrt( sqr(VdotX*ax) + sqr(VdotY*ay) + sqr(NdotV) ));
}

vec3 mon2lin(vec3 x)
{
    return vec3(pow(x[0], 2.2), pow(x[1], 2.2), pow(x[2], 2.2));
}


vec3 BRDF( vec3 L, vec3 V, vec3 N, vec3 X, vec3 Y )
{
    float NdotL = dot(N,L);
    float NdotV = dot(N,V);
    if (NdotL < 0 || NdotV < 0) return vec3(0);

    vec3 H = normalize(L+V);
    float NdotH = dot(N,H);
    float LdotH = dot(L,H);

    vec3 Cdlin = mon2lin(baseColor);
    float Cdlum = .3*Cdlin[0] + .6*Cdlin[1]  + .1*Cdlin[2]; // luminance approx.

    vec3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : vec3(1); // normalize lum. to isolate hue+sat
    vec3 Cspec0 = mix(specular*.08*mix(vec3(1), Ctint, specularTint), Cdlin, metallic);
    vec3 Csheen = mix(vec3(1), Ctint, sheenTint);

    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and mix in diffuse retro-reflection based on roughness
    float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
    float Fd90 = 0.5 + 2 * LdotH*LdotH * roughness;
    float Fd = mix(1.0, Fd90, FL) * mix(1.0, Fd90, FV);

    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    float Fss90 = LdotH*LdotH*roughness;
    float Fss = mix(1.0, Fss90, FL) * mix(1.0, Fss90, FV);
    float ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5);

    // specular
    float aspect = sqrt(1-anisotropic*.9);
    float ax = max(.001, sqr(roughness)/aspect);
    float ay = max(.001, sqr(roughness)*aspect);
    float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    float FH = SchlickFresnel(LdotH);
    vec3 Fs = mix(Cspec0, vec3(1), FH);
    float Gs;
    Gs  = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
    Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);

    // sheen
    vec3 Fsheen = FH * sheen * Csheen;

    // clearcoat (ior = 1.5 -> F0 = 0.04)
    float Dr = GTR1(NdotH, mix(.1,.001,clearcoatGloss));
    float Fr = mix(.04, 1.0, FH);
    float Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);

    return ((1/PI) * mix(Fd, ss, subsurface)*Cdlin + Fsheen)
        * (1-metallic)
        + Gs*Fs*Ds + .25*clearcoat*Gr*Fr*Dr;
}
// <END OF THIRD-PARTY SOURCE CODE>

void main()
{
    setSurfaceParams();

    // Obtemos a posição da câmera utilizando a inversa da matriz que define o
    // sistema de coordenadas da câmera.
    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    // O fragmento atual é coberto por um ponto que percente à superfície de um
    // dos objetos virtuais da cena. Este ponto, p, possui uma posição no
    // sistema de coordenadas global (World coordinates). Esta posição é obtida
    // através da interpolação, feita pelo rasterizador, da posição de cada
    // vértice.
    vec4 p = position_world;

    // Normal do fragmento atual, interpolada pelo rasterizador a partir das
    // normais de cada vértice.
    vec3 normal_direction = normalize(normal.xyz);

    // Vetor que define o sentido da câmera em relação ao ponto atual.
    vec3 view_direction = normalize((camera_position - p).xyz);

    // Parâmetros que definem as propriedades espectrais da superfície
    vec3 Kd; // Refletância difusa
    vec3 Ks; // Refletância especular
    vec3 Ka; // Refletância ambiente
    float q; // Expoente especular para o modelo de iluminação de Phong

	vec3 terra = vec3(0.30,0.16,0.07);

    if ( object_id == SPHERE || object_id == BUNNY )
    {
        // Materiais Disney definidos por surface_type.
        Kd = baseColor;
        Ks = vec3(0.0,0.0,0.0);
        Ka = Kd / 2;
        q = 1.0;
    }
    else if ( object_id == PLANE )
    {
        // Superfície de terra marrom fosca.
        Kd = terra;
        Ks = vec3(0.05,0.05,0.05);
        Ka = Kd / 2;
        q = 4.0;
    }
    else // Objeto desconhecido = preto
    {
        Kd = vec3(0.0,0.0,0.0);
        Ks = vec3(0.0,0.0,0.0);
        Ka = vec3(0.0,0.0,0.0);
        q = 1.0;
    }

    // Espectro da luz ambiente
    vec3 Ia = terra;

    // Termo ambiente
    vec3 ambient_term = Ka * Ia; // PREENCHA AQUI o termo ambiente

    vec3 direct_lighting = vec3(0.0);

    // NOTE: Se você quiser fazer o rendering de objetos transparentes, é
    // necessário:
    // 1) Habilitar a operação de "blending" de OpenGL logo antes de realizar o
    //    desenho dos objetos transparentes, com os comandos abaixo no código C++:
    //      glEnable(GL_BLEND);
    //      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    // 2) Realizar o desenho de todos objetos transparentes *após* ter desenhado
    //    todos os objetos opacos; e
    // 3) Realizar o desenho de objetos transparentes ordenados de acordo com
    //    suas distâncias para a câmera (desenhando primeiro objetos
    //    transparentes que estão mais longe da câmera).
    // Alpha default = 1 = 100% opaco = 0% transparente
    color.a = 1;

    if ( object_id == BUNNY || object_id == SPHERE )
    {
        vec3 tangent = cross(vec3(0,1,0), normal_direction);
        if ( length(tangent) < 0.001 )
        {
            tangent = cross(vec3(1,0,0), normal_direction);
        }
        tangent = normalize(tangent);
        vec3 bitangent = normalize(cross(normal_direction, tangent));

        for ( int light_index = 0; light_index < LIGHT_COUNT; ++light_index )
        {
            vec3 light_direction = normalize(LIGHT_DIRECTIONS[light_index]);
            vec3 light_color = LIGHT_COLORS[light_index];
            float NdotL = max(0.0, dot(normal_direction, light_direction));
            vec3 res = max(vec3(0.0), BRDF(light_direction, view_direction, normal_direction, tangent, bitangent));

            direct_lighting += light_color * res * NdotL;
        }

        color.rgb = direct_lighting + ambient_term;
    }
    else
    {
        for ( int light_index = 0; light_index < LIGHT_COUNT; ++light_index )
        {
            vec3 light_direction = normalize(LIGHT_DIRECTIONS[light_index]);
            vec3 light_color = LIGHT_COLORS[light_index];
            float NdotL = dot(normal_direction, light_direction);
            vec3 reflection_direction = -light_direction + 2.0 * normal_direction * NdotL;

            direct_lighting += Kd * light_color * max(0.0, NdotL);
            direct_lighting += Ks * light_color * pow(max(0.0, dot(reflection_direction, view_direction)), q);
        }

        // Cor final do fragmento calculada com uma combinação dos termos difuso,
        // especular, e ambiente. Veja {+Phong+}.
        color.rgb = direct_lighting + ambient_term;
    }

    // Cor final com correção gamma, considerando monitor sRGB.
    // Veja https://en.wikipedia.org/w/index.php?title=Gamma_correction&oldid=751281772#Windows.2C_Mac.2C_sRGB_and_TV.2Fvideo_standard_gammas
    color.rgb = pow(color.rgb, vec3(1.0,1.0,1.0)/2.2);
} 
