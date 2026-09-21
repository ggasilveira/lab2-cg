#include "solution.hpp"
#include "glm/common.hpp"
#include "glm/geometric.hpp"
#include "glm/glm.hpp"
#include "glm/vec2.hpp"
#include "matrices.h"
#include <algorithm>
#include <cmath>
#include <functional>
#include <iostream>

float calculate_dir(glm::vec2 pos1, glm::vec2 pos2) {
  glm::vec2 lookat = glm::normalize(pos1 - pos2);

  float angle = atan2(-lookat.y, lookat.x);
  return angle;
}

void State::update(float delta) {
  green_t += fmod(delta * green_speed, GREEN_MOD);
  yellow_t += fmod(delta * yellow_speed, yellow_perimeter());
  blue_t += fmod(delta * blue_speed, BLUE_MOD);
}

float jump(float height, float start, float end, float t) {
  float vx = (start + end) / 2.0;
  float a = (-height) / ((start - vx) * (start - vx));
  return std::max(a * (t - vx) * (t - vx) + height, 0.0f);
}

float rot_by_height(float amount, float height, float next_height) {
  return sin(height * 2.0f) * (atan(next_height - height) / 2.0 + M_PI_4);
}

/// Para a parte verde da bandeira, definimos uma função que
/// percorre repetidamente o retangulo.
/// Ajuda pensar em "abrir" as bordas do retangulo e deixar
/// em uma linha reta.
/// +-----W-----+
/// |           |
/// H           H
/// |           |
/// +-----W-----+
/// Vira:
/// |-----W-----|---H---|-----W-----|---H---|
/// A variável `green_t` é sempre modulo 2*W + 2*H,
/// então sempre fica dentro dessa linha.
/// A função encontra o segmento no qual está `green_t`
/// e reconstrói a posição no retângulo original.
glm::vec3 green_pos(float _t) {
  float t = fmod(_t, GREEN_MOD);
  float jmp_t = 0;
  glm::vec3 pos{0, 0, 0};

  if (t < FLAG_WIDTH) {
    jmp_t = t;
    pos.x = t;
  } else if (t < FLAG_WIDTH + FLAG_HEIGHT) {
    jmp_t = t - FLAG_WIDTH;
    pos.x = FLAG_WIDTH;
    pos.z = t - FLAG_WIDTH;
  } else if (t < 2 * FLAG_WIDTH + FLAG_HEIGHT) {
    jmp_t = t - FLAG_HEIGHT - FLAG_WIDTH;
    pos.x = FLAG_WIDTH - (t - FLAG_WIDTH - FLAG_HEIGHT);
    pos.z = FLAG_HEIGHT;
  } else {
    jmp_t = t - FLAG_HEIGHT - 2 * FLAG_WIDTH;
    pos.x = 0;
    pos.z = FLAG_HEIGHT - (t - 2 * FLAG_WIDTH - FLAG_HEIGHT);
  }

  pos.x -= FLAG_WIDTH / 2;
  pos.z -= FLAG_HEIGHT / 2;
  pos.y = jump(2.0f, 1.0f, std::min(FLAG_WIDTH, FLAG_HEIGHT) - 1.0, jmp_t);
  return pos;
}
glm::mat4 State::green_mat(float obj_step, int obj_i) {
  float t = green_t + obj_i * obj_step;
  glm::vec3 pos = green_pos(t);
  glm::vec3 next_pos = green_pos(t + 1.0f);
  // float angle = acos(glm::dot(lookat, x));
  float angle =
      calculate_dir(glm::vec2(pos.x, pos.z), glm::vec2(next_pos.x, next_pos.z));

  return Matrix_Translate(pos.x, pos.y, pos.z) * Matrix_Rotate_Y(angle) *
         Matrix_Rotate_Z(rot_by_height(1.f, pos.y, next_pos.y));
}

glm::vec3 State::yellow_pos(float _t) {
  glm::vec3 pos{0, 0, 0};
  float t = fmod(_t, yellow_perimeter());
  float t_progress = fmod(t, diamond_side) / diamond_side;
  glm::vec2 a{0, 0}, b{0, 0};
  if (t < diamond_side) {
    a.x = -DIAMOND_HOR / 2;
    b.y = -DIAMOND_VER / 2;
  } else if (t < 2 * diamond_side) {
    a.y = -DIAMOND_VER / 2;
    b.x = DIAMOND_HOR / 2;
  } else if (t < 3 * diamond_side) {
    a.x = DIAMOND_HOR / 2;
    b.y = DIAMOND_VER / 2;
  } else {
    a.y = DIAMOND_VER / 2;
    b.x = -DIAMOND_HOR / 2;
  }
  glm::vec2 pos_2d = glm::mix(a, b, t_progress);
  pos.x = pos_2d.x;
  pos.z = pos_2d.y;
  pos.y = jump(2.0f, 0.0f, diamond_side, fmod(t, diamond_side));

  return pos;
}

glm::mat4 State::yellow_mat(float obj_step, int obj_i) {
  float t = yellow_t + obj_i * obj_step;
  glm::vec3 pos = yellow_pos(t);
  glm::vec3 next_pos = yellow_pos(t + 1.0f);
  // float angle = acos(glm::dot(lookat, x));
  float angle =
      calculate_dir(glm::vec2(pos.x, pos.z), glm::vec2(next_pos.x, next_pos.z));

  return Matrix_Translate(pos.x, pos.y, pos.z) * Matrix_Rotate_Y(angle) *
         Matrix_Rotate_Z(rot_by_height(1.f, pos.y, next_pos.y));
}

glm::vec3 State::blue_pos(float _t) {
  glm::vec3 pos{0, 0, 0};
  float t = fmod(_t, BLUE_MOD);

  pos.x = cos(t) * CIRCLE_RADIUS + FLAG_WIDTH / 2.0 - FLAG_WIDTH / 2.0;
  pos.z = sin(t) * CIRCLE_RADIUS + FLAG_HEIGHT / 2.0 - FLAG_HEIGHT / 2.0;
  pos.y = jump(1.0f, 0.0f, M_PI_2, fmod(t, M_PI_2));

  return pos;
}

glm::mat4 State::blue_mat(float obj_step, int obj_i) {
  float t = blue_t + obj_i * obj_step;
  glm::vec3 pos = blue_pos(t);
  glm::vec3 next_pos = blue_pos(t + 1.0f);
  // float angle = acos(glm::dot(lookat, x));
  float angle =
      calculate_dir(glm::vec2(pos.x, pos.z), glm::vec2(next_pos.x, next_pos.z));

  return Matrix_Translate(pos.x, pos.y, pos.z) * Matrix_Rotate_Y(angle) *
         Matrix_Rotate_Z(rot_by_height(1.f, pos.y, next_pos.y));
}
