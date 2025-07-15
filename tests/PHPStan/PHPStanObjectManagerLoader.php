<?php

/**
 * @copyright 2023 Biapy
 * @license MIT
 */

declare(strict_types=1);

use App\Kernel;
use App\Tests\PHPStan\PHPStanObjectManager;
use Doctrine\Persistence\ManagerRegistry;

require dirname(__DIR__).'/../tests/bootstrap.php';

/** @psalm-suppress RedundantCondition,TypeDoesNotContainType */
$env = (isset($_SERVER['APP_ENV']) && is_string($_SERVER['APP_ENV'])) ? $_SERVER['APP_ENV'] : 'dev';
$debug = (bool) ($_SERVER['APP_DEBUG'] ?? false);

$kernel = new Kernel($env, $debug);
$kernel->boot();

$doctrineRegistries = [];

$registryNames = ['doctrine', 'doctrine_mongodb'];
foreach ($registryNames as $registryName) {
    if ($kernel->getContainer()->has($registryName)) {
        $doctrineRegistries[] = $kernel->getContainer()->get($registryName);
    }
}

if ([] === $doctrineRegistries) {
    throw new RuntimeException('Doctrine registries cannot be empty');
}

/** @var non-empty-array<array-key,ManagerRegistry> $doctrineRegistries */

return new PHPStanObjectManager($doctrineRegistries);
