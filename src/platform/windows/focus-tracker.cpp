#include <windows.h>
#include <stdio.h>
#include <time.h>
#include <winuser.h>

void clearScreen() {
    HANDLE console = GetStdHandle(STD_OUTPUT_HANDLE);

    // Get the console screen buffer info
    CONSOLE_SCREEN_BUFFER_INFO screen_buffer;
    GetConsoleScreenBufferInfo(console, &screen_buffer);

    // DWORD console_size = screen_buffer.dwSize.X * screen_buffer.dwSize.Y;

    COORD buffer_start = { 0, 0 };
    // DWORD chars_written;

    // // Fill the console with spaces to clear it
    // FillConsoleOutputCharacter(hConsole, ' ', consoleSize, topLeft, &charsWritten);

    // // Reset the console's attributes (e.g., colors)
    // FillConsoleOutputAttribute(hConsole, csbi.wAttributes, consoleSize, topLeft, &charsWritten);

    // Set the cursor position back to the top left
    SetConsoleCursorPosition(console, buffer_start);
}

void logFocusChange(HWND hwnd, time_t timestamp) {
    char windowTitle[256];
    GetWindowText(hwnd, windowTitle, sizeof(windowTitle));

    char className[256];
    GetClassName(hwnd, className, sizeof(className));

    // Convert timestamp to human-readable form
    char timeStr[100];
    struct tm timeinfo;
    localtime_s(&timeinfo, &timestamp);
    strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", &timeinfo);

    // clearScreen();
    printf("Focus changed to: %s at %s, %s\n", windowTitle, timeStr, className);
}

int main(int arguments_count, char* arguments_vector[])
{
    char* executable_absolute_path = arguments_vector[0];
    char* executable_dirname;

    // There are some commands that have to be considered.
    if (arguments_count > 1)
    {
        for (int i = 1; i < arguments_count; ++i)
            printf("%s\n", arguments_vector[i]);

        return 0;
    }

    HWND prev_window = 0;
    HWND curr_window;
    time_t timestamp;

    bool is_running = true;
    while (is_running)
    {
        curr_window = GetForegroundWindow();

        if (curr_window != prev_window)
        {
            time(&timestamp);
            logFocusChange(curr_window, timestamp);
            prev_window = curr_window;
        }

        Sleep(100);
    }

    return 0;
}
