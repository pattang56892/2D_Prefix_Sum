#include <iostream>
#include <algorithm>

using namespace std;

const int MAXC = 5005;
static int s[MAXC][MAXC];  // static to avoid stack overflow

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n, m;
    cin >> n >> m;

    // Read targets and accumulate values on grid
    // Shift by +1 to avoid negative index issues in prefix sum
    for (int i = 0; i < n; i++) {
        int x, y, v;
        cin >> x >> y >> v;
        s[x + 1][y + 1] += v;  // += handles multiple targets at same position
    }

    // Build 2D prefix sums in-place
    for (int i = 1; i < MAXC; i++) {
        for (int j = 1; j < MAXC; j++) {
            s[i][j] += s[i - 1][j] + s[i][j - 1] - s[i - 1][j - 1];
        }
    }

    int ans = 0;

    // Scan all possible m x m windows
    // Window size is m (not m-1) because placement is continuous
    for (int i = m; i < MAXC; i++) {
        for (int j = m; j < MAXC; j++) {
            // Rectangle sum from (i-m+1, j-m+1) to (i, j)
            int sum = s[i][j] - s[i - m][j] - s[i][j - m] + s[i - m][j - m];
            ans = max(ans, sum);
        }
    }

    cout << ans << endl;
    return 0;
}
