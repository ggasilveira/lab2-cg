#pragma once
#include "glm/mat4x4.hpp"
#include "glm/vec3.hpp"
#include <cmath>

constexpr float FLAG_WIDTH = 16.0f * 1.2f;
constexpr float FLAG_HEIGHT = 12.0f * 1.2f;
constexpr float GREEN_MOD = FLAG_WIDTH * 2 + FLAG_HEIGHT * 2;

constexpr float CIRCLE_RADIUS = 3.0f * 1.2f;
constexpr float BLUE_MOD = M_PI * 2.0f;

constexpr float DIAMOND_HOR = 14.0f * 1.2f;
constexpr float DIAMOND_VER = 10.0f * 1.2f;

constexpr float CURVE_RADIUS = 1.0f;

class State {
public:
  float green_speed;
  float yellow_speed;
  float blue_speed;
  State(float green_s, float yellow_s, float blue_s)
      : green_speed(green_s), yellow_speed(yellow_s), blue_speed(blue_s),
        diamond_side(
            sqrtf(DIAMOND_HOR * DIAMOND_HOR + DIAMOND_VER * DIAMOND_VER) / 2.0),
        yellow_perim(diamond_side * 4.0) {}

  void update(float delta);
  // glm::vec3 green_pos(float obj_step, int obj_i);
  glm::vec3 yellow_pos(float t);
  glm::vec3 blue_pos(float t);

  glm::mat4 green_mat(float obj_step, int obj_i);
  glm::mat4 yellow_mat(float obj_step, int obj_i);
  glm::mat4 blue_mat(float obj_step, int obj_i);

  float green_perimeter() const { return GREEN_MOD; }
  float blue_perimeter() const { return BLUE_MOD * CIRCLE_RADIUS; }
  float yellow_perimeter() const { return yellow_perim; }

private:
  float green_t = 0;
  float yellow_t = 0;
  float blue_t = 0;
  float diamond_side = 0;
  float yellow_perim = 0;
};
