package com.example.birdshop.config;

import com.example.birdshop.model.Bird;
import com.example.birdshop.repository.BirdRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner initDatabase(BirdRepository repository) {
        return args -> {
            repository.save(new Bird(null, "Blue Jay", "Beautiful Blue Jay with vibrant colors", 1999.99, "./images/blue-jay.jpg"));
            repository.save(new Bird(null, "Owl", "Majestic owl with keen eyesight", 1499.99, "./images/owl.jpg"));
            repository.save(new Bird(null, "Parrot", "Colorful talking parrot", 1299.99, "./images/parrot.jpg"));
            repository.save(new Bird(null, "Parakeet", "Colorful and playful Budgerigar", 49.99, "./images/Parakeet.jpg"));
            repository.save(new Bird(null, "Cockatiel", "Sweet and gentle Cockatiel", 79.99, "./images/Cockatiel.jpg"));
            repository.save(new Bird(null, "Canary", "Melodious Yellow Canary", 39.99, "./images/canary.jpg"));
        };
    }
}
