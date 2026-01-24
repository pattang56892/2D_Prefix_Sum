/*
 * 2D Prefix Sum - Maximum Window Sum Problem
 *
 * Problem: Given n points on a 2D grid, each with coordinates (x, y) and value v,
 * find the maximum total value of points that can be captured by placing one
 * axis-aligned square of side length m.
 *
 * Key Rule: Points on the boundary do NOT count - only points strictly inside.
 *
 * Solution Approach:
 * 1. Build a 2D grid accumulating values at each coordinate
 * 2. Compute 2D prefix sums for O(1) rectangle queries
 * 3. Scan all possible m x m windows and find the maximum sum
 *
 * Time Complexity: O(MAXC^2) where MAXC = 5005
 * Space Complexity: O(MAXC^2) for the prefix sum array
 */

#include <iostream>
#include <algorithm>
#include <windows.h>

using namespace std;

const int MAXC = 5005;              // Max coordinate value + buffer for 1-based indexing
static int s[MAXC][MAXC];           // Static array to avoid stack overflow (~100MB)

int main() {
    // Set console to UTF-8 encoding for Chinese characters
    SetConsoleOutputCP(65001);
    SetConsoleCP(65001);

    cout << "==========================================" << endl;
    cout << "  2D Prefix Sum - Max Window Problem     " << endl;
    cout << "  二维前缀和 - 最大窗口问题               " << endl;
    cout << "==========================================" << endl;
    cout << endl;

    // Get number of points and square size
    int n, m;
    cout << "Enter number of points (n) / 输入点的数量 (n): ";
    cin >> n;
    cout << "Enter square side length (m) / 输入正方形边长 (m): ";
    cin >> m;
    cout << endl;

    // Read each point's coordinates and value
    cout << "Enter " << n << " points (format: x y value):" << endl;
    cout << "输入 " << n << " 个点 (格式: x y 价值):" << endl;
    cout << "--------------------------------------------" << endl;

    for (int i = 0; i < n; i++) {
        int x, y, v;
        cout << "Point / 点 " << (i + 1) << ": ";
        cin >> x >> y >> v;

        // Shift by +1 to avoid negative index issues in prefix sum calculation
        // Use += to handle multiple points at the same coordinate
        s[x + 1][y + 1] += v;
    }
    cout << endl;

    cout << "Building 2D prefix sums... / 构建二维前缀和..." << endl;

    // Build 2D prefix sums in-place
    // s[i][j] = sum of all values in rectangle from (1,1) to (i,j)
    // Formula: s[i][j] = current + left + top - top_left (avoid double counting)
    for (int i = 1; i < MAXC; i++) {
        for (int j = 1; j < MAXC; j++) {
            s[i][j] += s[i - 1][j] + s[i][j - 1] - s[i - 1][j - 1];
        }
    }

    cout << "Scanning all possible " << m << "x" << m << " windows... / 扫描所有可能的 " << m << "x" << m << " 窗口..." << endl;

    int ans = 0;

    // Scan all possible m x m windows
    // Window size is m (not m-1) because placement is continuous
    // We can always shift the square slightly to avoid points on boundary
    for (int i = m; i < MAXC; i++) {
        for (int j = m; j < MAXC; j++) {
            // Rectangle sum formula for window ending at (i, j)
            // Sum = bottom_right - left_strip - top_strip + top_left_corner
            int sum = s[i][j] - s[i - m][j] - s[i][j - m] + s[i - m][j - m];
            ans = max(ans, sum);
        }
    }

    // Display result
    cout << endl;
    cout << "==========================================" << endl;
    cout << "  RESULT / 结果: Maximum value / 最大值 = " << ans << endl;
    cout << "==========================================" << endl;

    return 0;
}

/*
 * ==========================================
 * 简体中文翻译 (Simplified Chinese Translation)
 * ==========================================
 *
 * 题目描述:
 * 在一个二维网格上有 n 个点。
 * 每个点有坐标 (x, y) 和一个价值 v。
 * 你可以在地图上放置一个边长为 m 的正方形。
 *
 * 正方形的规则:
 * - 正方形的边必须与 x 轴和 y 轴平行（不能旋转）
 * - 只有严格在正方形内部的点才算数
 * - 如果一个点刚好在正方形的边界上，它不算被覆盖
 *
 * 你的任务:
 * 找到放置正方形的最佳位置，使得正方形内部的点的价值总和最大。
 *
 * 输入格式:
 * - 第一行：两个整数 n 和 m
 * - 接下来 n 行：每行三个整数 x y v，表示点的坐标和价值
 *
 * 输出格式:
 * - 输出一个正整数：表示一次放置能够覆盖到的点的最大价值总和
 *
 * 示例:
 * 输入:
 * 2 1
 * 0 0 1
 * 1 1 1
 *
 * 输出:
 * 1
 *
 * 解释: 边长为 1 的正方形一次只能覆盖一个点，所以最大值是 1。
 *
 * 约束条件:
 * - 1 <= n <= 10^4
 * - 0 <= x, y <= 5000
 * - 1 <= m <= 5000
 * - 1 <= v < 100
 * - 答案不会超过 32767
 */
