<?php

/**
 * @copyright 2023 Biapy
 * @license MIT
 */

declare(strict_types=1);

namespace App\Tests\PHPStan;

use Doctrine\Persistence\ManagerRegistry;
use Doctrine\Persistence\Mapping\ClassMetadata;
use Doctrine\Persistence\Mapping\ClassMetadataFactory;
use Doctrine\Persistence\ObjectManager;

/**
 * @template T of ClassMetadata<object>
 *
 * @implements ClassMetadataFactory<T>
 */
final class PHPStanMetadataFactory implements ClassMetadataFactory
{
    /**
     * Last used object manager.
     */
    private ?ObjectManager $manager = null;

    /**
     * @param non-empty-array<array-key,ManagerRegistry> $doctrineRegistries
     */
    public function __construct(
        private array $doctrineRegistries,
    ) {
        if([] === $doctrineRegistries) {
            throw new \InvalidArgumentException('Doctrine registries cannot be empty');
        }
    }

    /**
     * @return ClassMetadata<object>[]
     * @psalm-return list<T>
     */
    #[\Override]
    public function getAllMetadata(): array
    {
        /**
         * @psalm-var list<T>
         */
        $result = array_merge(...array_map(
            fn (ObjectManager $manager): array => $manager->getMetadataFactory()->getAllMetadata(),
            array_values($this->getAllManagers()),
        ));

        return $result;
    }

    /**
     * @param class-string $className
     *
     * @return ClassMetadata<object>
     * @psalm-return T
     */
    #[\Override]
    public function getMetadataFor(string $className): ClassMetadata
    {
        $manager = $this->getManagerForClass($className);

        if (!$manager instanceof ObjectManager) {
            reset($this->doctrineRegistries);
            $manager = current($this->doctrineRegistries)->getManager();
        }

        /** @psalm-var T $metadata */
        $metadata = $manager->getClassMetadata($className);

        return $metadata;
    }

    /**
     * @param class-string $className
     */
    #[\Override]
    public function isTransient(string $className): bool
    {
        $manager = $this->getManagerForClass($className);

        if (!$manager instanceof ObjectManager) {
            return true;
        }

        return $manager->getMetadataFactory()->isTransient($className);
    }

    /**
     * @param class-string $className
     */
    #[\Override]
    public function hasMetadataFor(string $className): bool
    {
        $manager = $this->getManagerForClass($className);

        if (!$manager instanceof ObjectManager) {
            return false;
        }

        return $manager->getMetadataFactory()->hasMetadataFor($className);
    }

    /**
     * @param class-string          $className
     * @param ClassMetadata<object> $class
     * @psalm-param T $class
     */
    #[\Override]
    public function setMetadataFor(string $className, ClassMetadata $class): void
    {
        $manager = $this->getManagerForClass($className);

        if (!$manager instanceof ObjectManager) {
            throw new \RuntimeException(sprintf('No manager found for class "%s"', $className));
        }

        $manager->getMetadataFactory()->setMetadataFor($className, $class);
    }

    /**
     * @param class-string $className
     */
    public function getManagerForClass(string $className): ?ObjectManager
    {
        if ($this->manager instanceof ObjectManager && $this->manager->getMetadataFactory()->hasMetadataFor($className)) {
            return $this->manager;
        }

        foreach ($this->doctrineRegistries as $doctrine) {
            $manager = $doctrine->getManagerForClass($className);
            if (null !== $manager) {
                $this->manager = $manager;

                return $manager;
            }
        }

        return null;
    }

    /**
     * @return array<string,ObjectManager>
     */
    private function getAllManagers(): array
    {
        return array_merge(...array_map(
            /**
             * @return array<string,ObjectManager>
             */
            fn (ManagerRegistry $registry): array => $registry->getManagers(),
            $this->doctrineRegistries,
        ));
    }
}
