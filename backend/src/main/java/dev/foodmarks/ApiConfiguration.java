package dev.foodmarks;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.*;

@Configuration
public class ApiConfiguration implements WebMvcConfigurer {
    private final String origins;
    public ApiConfiguration(@Value("${app.cors-origins}") String origins) { this.origins = origins; }
    @Override public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**").allowedOriginPatterns(origins.split(","))
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS");
    }
}
