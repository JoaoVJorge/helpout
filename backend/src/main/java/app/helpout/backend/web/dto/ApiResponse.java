package app.helpout.backend.web.dto;

public record ApiResponse<T>(T data, String message) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(data, "OK");
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(data, message);
    }

    public static ApiResponse<Void> error(String message) {
        return new ApiResponse<>(null, message);
    }
}
